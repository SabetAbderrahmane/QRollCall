from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth
from app.core.config import get_settings
from app.routes import auth, events



settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    debug=settings.app_debug,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this later in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(events.router, tags=["events"])

@app.get("/")
def root():
    return {"message": f"Welcome to {settings.app_name}", "environment": settings.app_env}

@app.get("/health")
def health_check():
    return {"status": "ok"}
