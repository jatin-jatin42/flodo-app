from pydantic import BaseModel
from datetime import date
from typing import Optional
from uuid import UUID
from .models import TaskStatus, RecurrenceInterval

class TaskBase(BaseModel):
    title: str
    description: str
    due_date: date
    status: TaskStatus = TaskStatus.TODO
    blocked_by_id: Optional[UUID] = None
    order_index: float = 0.0
    is_recurring: bool = False
    recurrence_interval: Optional[RecurrenceInterval] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[date] = None
    status: Optional[TaskStatus] = None
    blocked_by_id: Optional[UUID] = None
    order_index: Optional[float] = None
    is_recurring: Optional[bool] = None
    recurrence_interval: Optional[RecurrenceInterval] = None

class TaskResponse(TaskBase):
    id: UUID
    
    model_config = {"from_attributes": True}

class TaskReorder(BaseModel):
    new_order_index: float
