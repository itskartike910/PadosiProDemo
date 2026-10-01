"""
PadosiPro Backend — Standard API response helpers
"""
from typing import Any
from fastapi.responses import JSONResponse


def ok(data: Any = None, message: str = "Success", status_code: int = 200) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "success": True,
            "message": message,
            "data": data,
        },
    )


def created(data: Any = None, message: str = "Created") -> JSONResponse:
    return ok(data=data, message=message, status_code=201)


def error(code: str, message: str, status_code: int = 400, data: Any = None) -> JSONResponse:
    content = {
        "success": False,
        "error": {
            "code": code,
            "message": message,
        },
    }
    if data is not None:
        content["data"] = data
    return JSONResponse(status_code=status_code, content=content)
