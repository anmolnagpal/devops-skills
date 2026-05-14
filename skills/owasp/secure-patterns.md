# Secure Code Patterns

Safe vs unsafe patterns for the most common vulnerability classes.

## SQL Injection Prevention
```python
# UNSAFE
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# SAFE
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

## Command Injection Prevention
```python
# UNSAFE
os.system(f"convert {filename} output.png")

# SAFE
subprocess.run(["convert", filename, "output.png"], shell=False)
```

## Password Storage
```python
# UNSAFE
hashlib.md5(password.encode()).hexdigest()

# SAFE
from argon2 import PasswordHasher
PasswordHasher().hash(password)
```

## Access Control
```python
# UNSAFE — No authorization check
@app.route('/api/user/<user_id>')
def get_user(user_id):
    return db.get_user(user_id)

# SAFE — Authorization enforced
@app.route('/api/user/<user_id>')
@login_required
def get_user(user_id):
    if current_user.id != user_id and not current_user.is_admin:
        abort(403)
    return db.get_user(user_id)
```

## Error Handling
```python
# UNSAFE — Exposes internals
@app.errorhandler(Exception)
def handle_error(e):
    return str(e), 500

# SAFE — Fail-closed, log context
@app.errorhandler(Exception)
def handle_error(e):
    error_id = uuid.uuid4()
    logger.exception(f"Error {error_id}: {e}")
    return {"error": "An error occurred", "id": str(error_id)}, 500
```

## Fail-Closed Pattern
```python
# UNSAFE — Fail-open
def check_permission(user, resource):
    try:
        return auth_service.check(user, resource)
    except Exception:
        return True  # DANGEROUS

# SAFE — Fail-closed
def check_permission(user, resource):
    try:
        return auth_service.check(user, resource)
    except Exception as e:
        logger.error(f"Auth check failed: {e}")
        return False  # Deny on error
```
