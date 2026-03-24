import uuid
import enum
from sqlalchemy import Column, String, Text, Date, Enum, Float, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from .database import Base

class TaskStatus(str, enum.Enum):
    TODO = "To-Do"
    IN_PROGRESS = "In Progress"
    DONE = "Done"

class RecurrenceInterval(str, enum.Enum):
    DAILY = "Daily"
    WEEKLY = "Weekly"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    due_date = Column(Date, nullable=False)
    status = Column(Enum(TaskStatus, name="taskstatus"), default=TaskStatus.TODO, nullable=False)
    
    blocked_by_id = Column(UUID(as_uuid=True), ForeignKey("tasks.id"), nullable=True)
    
    order_index = Column(Float, default=0.0, nullable=False)
    
    is_recurring = Column(Boolean, default=False, nullable=False)
    recurrence_interval = Column(Enum(RecurrenceInterval, name="recurrenceinterval"), nullable=True)
