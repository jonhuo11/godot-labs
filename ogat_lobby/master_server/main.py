from typing import Dict, Tuple
from abc import ABC, abstractmethod
from fastapi import FastAPI, HTTPException
import asyncio
from contextlib import asynccontextmanager

class RWLock:
    def __init__(self):
        self._readers = 0
        self._readers_lock = asyncio.Lock()
        self._writer_lock = asyncio.Lock()

    @asynccontextmanager
    async def read(self):
        async with self._readers_lock:
            self._readers += 1
            if self._readers == 1:
                await self._writer_lock.acquire()
        try:
            yield
        finally:
            async with self._readers_lock:
                self._readers -= 1
                if self._readers == 0:
                    self._writer_lock.release()

    @asynccontextmanager
    async def write(self):
        await self._writer_lock.acquire()
        try:
            yield
        finally:
            self._writer_lock.release()


class Serializable(ABC):
    @abstractmethod
    def json(self) -> dict:
        raise NotImplementedError


type ServerTuple = Tuple[str, int, str, int]
# ip, port, name, max_players


class Server(Serializable):
    def __init__(self, server_tuple: ServerTuple):
        ip, port, name, max_players = server_tuple
        self.ip = ip
        self.port = port
        self.name = name
        self.max_players = max_players

    def json(self) -> dict:
        return {
            "ip": self.ip,
            "port": self.port,
            "name": self.name,
            "max_players": self.max_players,
        }

    @classmethod
    def from_json(cls, json: dict, name: str) -> "Server":
        return cls((
            json["ip"],
            int(json["port"]),
            name,
            int(json["max_players"]),
        ))


class ServerList(Serializable):
    def __init__(self):
        self._list: Dict[str, Server] = {}
        self._m: RWLock = RWLock()

    async def add(self, server: Server) -> bool:
        async with self._m.write():
            if server.name in self._list:
                return False
            self._list[server.name] = server
            return True

    async def list(self) -> dict:
        async with self._m.read():
            return self.json()

    def json(self) -> dict:
        return {
            "servers": {name: srv.json() for name, srv in self._list.items()}
        }


server_list = ServerList()
app = FastAPI()


@app.get("/")
async def root():
    return await server_list.list()


@app.put("/lobbies/{lobby_name}", status_code=201)
async def add_lobby(lobby_name: str, body: dict):
    # Minimal validation
    for k in ("ip", "port", "max_players"):
        if k not in body:
            raise HTTPException(400, f"missing field: {k}")

    try:
        server = Server.from_json(body, lobby_name)
    except Exception:
        raise HTTPException(400, "invalid field types")

    if server.port < 1 or server.port > 65535:
        raise HTTPException(400, "port out of range")
    if server.max_players <= 0:
        raise HTTPException(400, "max_players must be > 0")

    ok = await server_list.add(server)
    if not ok:
        raise HTTPException(409, "lobby already exists")

    return {"ok": True, "lobby": server.json()}


@app.get("/ok")
async def ok():
    return {"ok": True}
