from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, asc, update
from typing import List
from uuid import UUID
from datetime import timedelta

from ..database import get_db
from ..models import Task, TaskStatus
from ..schemas import TaskCreate, TaskUpdate, TaskResponse, TaskReorder

router = APIRouter(prefix="/tasks", tags=["Tasks"])

@router.get("/", response_model=List[TaskResponse])
async def list_tasks(
    search: str = Query(None, description="Search by title"),
    status: TaskStatus = Query(None, description="Filter by status"),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Task).order_by(asc(Task.order_index))
    if search:
        stmt = stmt.filter(Task.title.ilike(f"%{search}%"))
    if status:
        stmt = stmt.filter(Task.status == status)
    
    result = await db.execute(stmt)
    return result.scalars().all()

@router.post("/", response_model=TaskResponse)
async def create_task(task_in: TaskCreate, db: AsyncSession = Depends(get_db)):
    # Calculate a valid order_index (append to end)
    result = await db.execute(select(Task).order_by(Task.order_index.desc()).limit(1))
    last_task = result.scalars().first()
    new_order = last_task.order_index + 1.0 if last_task else 0.0

    task = Task(**task_in.model_dump(exclude={"order_index"}), order_index=new_order)
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return task

@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(task_id: UUID, db: AsyncSession = Depends(get_db)):
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(task_id: UUID, task_in: TaskUpdate, db: AsyncSession = Depends(get_db)):
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    update_data = task_in.model_dump(exclude_unset=True)
    
    # Check for stretch goal #2: Recurring task logic
    marking_done = False
    if "status" in update_data and update_data["status"] == TaskStatus.DONE and task.status != TaskStatus.DONE:
        marking_done = True
        
    for field, value in update_data.items():
        setattr(task, field, value)
        
    db.add(task)
    
    if marking_done and task.is_recurring and task.recurrence_interval:
        # Create a new task pushed forward
        new_due_date = task.due_date
        if task.recurrence_interval.value == "Daily":
            new_due_date += timedelta(days=1)
        elif task.recurrence_interval.value == "Weekly":
            new_due_date += timedelta(weeks=1)
            
        new_task = Task(
            title=task.title,
            description=task.description,
            due_date=new_due_date,
            status=TaskStatus.TODO,
            blocked_by_id=task.blocked_by_id,
            order_index=task.order_index + 0.1,  # Place right after
            is_recurring=True,
            recurrence_interval=task.recurrence_interval
        )
        db.add(new_task)

    await db.commit()
    await db.refresh(task)
    return task

@router.post("/{task_id}/reorder", response_model=TaskResponse)
async def reorder_task(task_id: UUID, reorder_in: TaskReorder, db: AsyncSession = Depends(get_db)):
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task.order_index = reorder_in.new_order_index
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return task

@router.delete("/{task_id}")
async def delete_task(task_id: UUID, db: AsyncSession = Depends(get_db)):
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Clear any references to this task before deleting (avoid FK violation)
    await db.execute(
        update(Task).where(Task.blocked_by_id == task_id).values(blocked_by_id=None)
    )
    
    await db.delete(task)
    await db.commit()
    return {"message": "Task deleted"}
