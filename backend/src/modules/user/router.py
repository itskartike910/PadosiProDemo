"""
PadosiPro Backend — User module: profile CRUD + task selection
"""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from ...database import get_db
from ...models import Task, User, UserRequest, UserTask
from ...modules.auth.router import get_current_user, _user_dict
from ...responses import error, ok

router = APIRouter(prefix="/users", tags=["users"])


# ── Schemas ──────────────────────────────────────────────────────────────────


class CreateUserRequest(BaseModel):
    category_name: str
    service_name: str
    timing: str = "Standard"
    notes: str | None = None


def _request_dict(req: UserRequest) -> dict:
    return {
        "id": req.id,
        "user_id": req.user_id,
        "category_name": req.category_name,
        "service_name": req.service_name,
        "timing": req.timing,
        "notes": req.notes,
        "status": req.status,
        "created_at": req.created_at.isoformat() if req.created_at else None,
        "updated_at": req.updated_at.isoformat() if req.updated_at else None,
    }


class UpdateProfileRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    phone_number: str | None = Field(None, min_length=10, max_length=15)
    address: str | None = Field(None, max_length=500)
    society: str | None = Field(None, max_length=200)
    flat_unit: str | None = Field(None, max_length=100)
    gate_notes: str | None = Field(None, max_length=500)
    business_name: str | None = Field(None, max_length=200)


class SaveTasksRequest(BaseModel):
    task_ids: list[str]


# ── Routes ───────────────────────────────────────────────────────────────────


@router.get("/me")
async def get_profile(current_user: User = Depends(get_current_user)):
    return ok(_user_dict(current_user))


@router.put("/me/profile")
async def update_profile(
    body: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current_user.name = body.name
    if body.phone_number is not None:
        current_user.phone_number = body.phone_number
    current_user.address = body.address
    current_user.society = body.society
    current_user.flat_unit = body.flat_unit
    current_user.gate_notes = body.gate_notes
    current_user.business_name = body.business_name

    # Mark profile complete if minimum required fields are present
    current_user.is_profile_complete = bool(current_user.name and current_user.address)

    await db.commit()
    await db.refresh(current_user)
    return ok(_user_dict(current_user), "Profile updated.")


@router.get("/me/tasks")
async def get_my_tasks(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserTask).where(UserTask.user_id == current_user.id)
    )
    user_tasks = result.scalars().all()

    if not user_tasks:
        return ok({"task_ids": [], "tasks": []})

    task_ids = [ut.task_id for ut in user_tasks]
    tasks_result = await db.execute(select(Task).where(Task.id.in_(task_ids)))
    tasks = tasks_result.scalars().all()

    return ok({
        "task_ids": task_ids,
        "tasks": [
            {
                "id": t.id,
                "name": t.name,
                "description": t.description,
                "category_id": t.category_id,
            }
            for t in tasks
        ],
    })


@router.post("/me/tasks")
async def save_my_tasks(
    body: SaveTasksRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Validate task IDs exist
    if body.task_ids:
        result = await db.execute(select(Task).where(Task.id.in_(body.task_ids)))
        found_tasks = result.scalars().all()
        found_ids = {t.id for t in found_tasks}
        invalid = set(body.task_ids) - found_ids
        if invalid:
            return error("INVALID_TASK_IDS", f"Unknown task IDs: {', '.join(invalid)}")

    # Replace all user tasks
    await db.execute(delete(UserTask).where(UserTask.user_id == current_user.id))
    for task_id in body.task_ids:
        db.add(UserTask(user_id=current_user.id, task_id=task_id))

    await db.commit()
    return ok({"task_ids": body.task_ids}, "Tasks saved.")


@router.post("/me/requests")
async def create_request(
    body: CreateUserRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    req = UserRequest(
        user_id=current_user.id,
        category_name=body.category_name,
        service_name=body.service_name,
        timing=body.timing,
        notes=body.notes,
        status="We are looking at it",
    )
    db.add(req)
    await db.commit()
    await db.refresh(req)
    return ok(_request_dict(req), "Request submitted successfully.")


@router.get("/me/requests/active")
async def get_active_request(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserRequest)
        .where(UserRequest.user_id == current_user.id)
        .order_by(UserRequest.created_at.desc())
        .limit(1)
    )
    active = result.scalar_one_or_none()
    return ok(_request_dict(active) if active else None)
