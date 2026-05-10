from fastapi import HTTPException
from core.security import hash_password


def normalize_gemini_key(value: str | None):
    if value is None:
        return None

    value = value.strip()

    if value == "":
        return None

    return value


def mask_gemini_key(key: str | None):
    if not key:
        return None

    if len(key) <= 8:
        return "****"

    return f"{key[:4]}****{key[-4:]}"


async def get_user_by_email(conn, email: str):
    async with conn.cursor() as cur:
        await cur.execute(
            "SELECT * FROM users WHERE email = %s",
            (email,)
        )
        return await cur.fetchone()


async def create_user(conn, fullname: str, email: str, password: str, gemini_api_key: str | None):
    existing_user = await get_user_by_email(conn, email)

    if existing_user:
        raise HTTPException(status_code=400, detail="Email already exists")

    hashed_password = hash_password(password)
    gemini_key = normalize_gemini_key(gemini_api_key)

    async with conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO users (fullname, email, password, gemini_api_key)
            VALUES (%s, %s, %s, %s)
            """,
            (fullname, email, hashed_password, gemini_key)
        )
        await conn.commit()

    return {
        "message": "Register successful"
    }


async def get_profile(conn, user_id: int):
    async with conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, fullname, email, profile_image, gemini_api_key
            FROM users
            WHERE id = %s
            """,
            (user_id,)
        )
        user = await cur.fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    gemini_key = user.get("gemini_api_key")

    return {
        "id": user["id"],
        "fullname": user["fullname"],
        "email": user["email"],
        "profile_image": user.get("profile_image"),
        "has_gemini_api_key": gemini_key is not None and gemini_key != "",
        "masked_gemini_api_key": mask_gemini_key(gemini_key),
    }


async def update_profile(
    conn,
    user_id: int,
    fullname: str,
    profile_image: str | None,
    gemini_api_key: str | None,
):
    gemini_key = normalize_gemini_key(gemini_api_key)

    async with conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE users
            SET fullname = %s,
                profile_image = %s,
                gemini_api_key = %s
            WHERE id = %s
            """,
            (fullname, profile_image, gemini_key, user_id)
        )
        await conn.commit()

    return await get_profile(conn, user_id)