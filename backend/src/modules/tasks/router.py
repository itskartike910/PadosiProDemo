"""
PadosiPro Backend — Tasks module: catalogue (categories + tasks)
"""
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ...database import get_db
from ...models import Category, Task
from ...responses import ok

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("/categories")
async def get_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Category).order_by(Category.order)
    )
    categories = result.scalars().all()
    return ok([
        {
            "id": c.id,
            "name": c.name,
            "subtitle": c.subtitle,
            "icon": c.icon,
            "is_coming_soon": c.is_coming_soon,
        }
        for c in categories
    ])


@router.get("")
async def get_all_tasks(db: AsyncSession = Depends(get_db)):
    """Return all tasks grouped by category."""
    result = await db.execute(
        select(Category)
        .options(selectinload(Category.tasks))
        .order_by(Category.order)
    )
    categories = result.scalars().all()

    return ok([
        {
            "id": cat.id,
            "name": cat.name,
            "subtitle": cat.subtitle,
            "icon": cat.icon,
            "is_coming_soon": cat.is_coming_soon,
            "tasks": [
                {
                    "id": t.id,
                    "name": t.name,
                    "description": t.description,
                    "category_id": t.category_id,
                }
                for t in cat.tasks
            ],
        }
        for cat in categories
    ])
