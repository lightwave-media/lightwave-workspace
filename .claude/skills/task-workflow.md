# Skill: Task-Driven Development Workflow

**Purpose**: Complete TDD feature implementation following LightWave standards.

**When to use**: When implementing new features, fixing bugs, or making significant code changes.

**Prerequisites**:
- Task definition loaded from `.agent/tasks/{task-id}.yaml`
- Repository identified and checked out
- Environment set up (dependencies installed, secrets loaded)

---

## Workflow Overview

```
1. Load Task Context
2. Plan Implementation
3. Write Tests (RED)
4. Implement Feature (GREEN)
5. Refactor (REFACTOR)
6. Verify & Document
7. Commit & Push
8. Create PR
```

**Time estimate**: 30 minutes to 4 hours depending on complexity.

---

## Step 1: Load Task Context

### 1.1 Read Task Definition

```bash
# List available tasks
ls -la .agent/tasks/

# Read specific task
cat .agent/tasks/{task-id}.yaml
```

**Extract**:
- Task ID
- Description
- Acceptance criteria
- Dependencies
- Files to modify

### 1.2 Load Relevant Architecture

```bash
# Check tech stack
cat .agent/metadata/tech_stack.yaml

# For backend tasks
cat .agent/metadata/backend_architecture.yaml

# For frontend tasks
cat .agent/metadata/frontend_architecture.yaml

# For API work
cat .agent/metadata/api_design.yaml
```

### 1.3 Read Relevant SOP

```bash
# List available SOPs
ls -la .agent/sops/

# Read relevant SOP
cat .agent/sops/SOP_{TASK_TYPE}.md
```

**Common SOPs**:
- `SOP_TDD_SELF_HEALING_LOOP.md` - TDD workflow
- `SOP_DEPLOYMENT_HEALTH_TROUBLESHOOTING.md` - Deployment issues
- `THE_COMPLETE_GIT_WORKFLOW.md` - Git operations

---

## Step 2: Plan Implementation

### 2.1 Identify Affected Components

**Ask**:
- Which files need changes?
- Which modules are affected?
- Are there dependencies?
- Do we need database migrations?

**Document**:
```bash
# Create implementation notes
# (Mental notes or comments in task tracking)

Components to modify:
- models.py (add new field)
- serializers.py (update serializer)
- views.py (add new endpoint)
- tests/test_views.py (add test cases)

Dependencies:
- Django REST Framework
- PostgreSQL (migration needed)
```

### 2.2 Create Branch

```bash
# Navigate to repository
cd {REPO_PATH}

# Check current branch
git branch --show-current

# Create feature branch
git checkout -b feature/{task-id}-{short-description}

# Example:
git checkout -b feature/AUTH-123-add-email-verification

# Verify
git branch --show-current
```

---

## Step 3: Write Tests (RED)

### 3.1 Identify Test Cases

**From acceptance criteria**, create test cases for:
- Happy path (success scenario)
- Edge cases (boundaries, empty values)
- Error cases (validation failures, permissions)

**Example** (Django REST API):
```python
# tests/test_email_verification.py

def test_send_verification_email_success():
    """Should send verification email to valid user."""
    pass  # Will fail initially

def test_send_verification_email_invalid_user():
    """Should return 404 for non-existent user."""
    pass

def test_verify_email_with_valid_token():
    """Should verify email with valid token."""
    pass

def test_verify_email_with_expired_token():
    """Should reject expired token."""
    pass
```

### 3.2 Run Tests (Expect Failure)

```bash
# Backend (Django)
pytest tests/test_email_verification.py -v

# Frontend (Next.js)
pnpm test src/components/EmailVerification.test.tsx

# Expected: All tests FAIL (RED state)
```

**Document failures**:
```
❌ test_send_verification_email_success - NotImplementedError
❌ test_verify_email_with_valid_token - NotImplementedError
```

---

## Step 4: Implement Feature (GREEN)

### 4.1 Write Minimal Code to Pass Tests

**Goal**: Make tests pass with simplest implementation.

**Example** (Django):
```python
# models.py
class EmailVerification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    token = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True)

# views.py
class SendVerificationEmailView(APIView):
    def post(self, request):
        user = request.user
        token = generate_verification_token()
        EmailVerification.objects.create(user=user, token=token)
        send_verification_email(user.email, token)
        return Response({"status": "sent"}, status=200)
```

### 4.2 Run Tests Again

```bash
# Backend
pytest tests/test_email_verification.py -v

# Expected: All tests PASS (GREEN state)
```

**Document successes**:
```
✅ test_send_verification_email_success - PASSED
✅ test_verify_email_with_valid_token - PASSED
```

### 4.3 Handle Database Migrations (if needed)

```bash
# Django
python manage.py makemigrations
python manage.py migrate

# Verify migration created
ls -la */migrations/
```

---

## Step 5: Refactor (REFACTOR)

### 5.1 Improve Code Quality

**Check for**:
- Code duplication
- Magic numbers/strings
- Long functions (>20 lines)
- Missing docstrings
- Complex conditionals

**Refactor example**:
```python
# Before
def verify_email(token):
    try:
        verification = EmailVerification.objects.get(token=token)
        if (timezone.now() - verification.created_at).days > 7:
            return False
        verification.verified_at = timezone.now()
        verification.save()
        return True
    except EmailVerification.DoesNotExist:
        return False

# After
class EmailVerification(models.Model):
    TOKEN_EXPIRY_DAYS = 7  # Constant instead of magic number

    def is_expired(self):
        """Check if verification token is expired."""
        age = timezone.now() - self.created_at
        return age.days > self.TOKEN_EXPIRY_DAYS

    def verify(self):
        """Mark email as verified."""
        if self.is_expired():
            raise ValueError("Token expired")
        self.verified_at = timezone.now()
        self.save()

# View becomes simpler
def verify_email(token):
    try:
        verification = EmailVerification.objects.get(token=token)
        verification.verify()
        return True
    except (EmailVerification.DoesNotExist, ValueError):
        return False
```

### 5.2 Run Tests After Refactoring

```bash
# All tests should still pass
pytest tests/test_email_verification.py -v

# Expected: ✅ All tests PASS
```

### 5.3 Run Linting

```bash
# Backend (Python)
ruff check .
ruff format .

# Frontend (TypeScript)
pnpm lint
pnpm format

# Fix any issues
```

---

## Step 6: Verify & Document

### 6.1 Run Full Test Suite

```bash
# Backend
pytest

# Frontend
pnpm test

# Expected: All tests pass (not just new tests)
```

### 6.2 Manual Testing

**Test locally**:
```bash
# Backend
python manage.py runserver

# Frontend
pnpm dev

# Test in browser/Postman
# Verify expected behavior matches acceptance criteria
```

### 6.3 Update Documentation (if needed)

**Add docstrings**:
```python
def send_verification_email(user, token):
    """
    Send email verification link to user.

    Args:
        user: User instance
        token: Verification token string

    Returns:
        bool: True if email sent successfully

    Raises:
        EmailSendError: If email service fails
    """
    ...
```

**Update README** (if API changed):
```markdown
## Email Verification API

POST /api/auth/send-verification/
- Sends verification email to authenticated user
- Returns: {"status": "sent"}

POST /api/auth/verify-email/
- Body: {"token": "abc123"}
- Returns: {"status": "verified"}
```

---

## Step 7: Commit & Push

### 7.1 Stage Changes

```bash
# Check what changed
git status

# Review changes
git diff

# Stage files
git add {files}

# Or stage all
git add .
```

### 7.2 Commit

```bash
# Commit with conventional commit message
git commit -m "feat(auth): add email verification endpoint

- Add EmailVerification model
- Add send-verification and verify-email endpoints
- Add tests for email verification flow
- Update API documentation

Closes #AUTH-123"
```

**Commit message format**:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `test`: Test additions
- `docs`: Documentation
- `chore`: Maintenance

### 7.3 Push Branch

```bash
# Push to remote
git push -u origin feature/{task-id}-{description}

# Verify pushed
git branch -vv
```

---

## Step 8: Create PR

### 8.1 Create Pull Request

```bash
# Using GitHub CLI
gh pr create \
  --title "feat(auth): Add email verification endpoint" \
  --body "$(cat <<'EOF'
## Summary
- Implements email verification flow for user accounts
- Adds new EmailVerification model
- Adds API endpoints for sending and verifying emails

## Changes
- Added EmailVerification model with token and expiry
- Added POST /api/auth/send-verification/ endpoint
- Added POST /api/auth/verify-email/ endpoint
- Added comprehensive test coverage (95%+)

## Testing
- All tests pass
- Manual testing completed
- Edge cases covered

## Related
Closes #AUTH-123

🤖 Generated with Claude Code
EOF
)"
```

### 8.2 Verify PR

```bash
# Check PR status
gh pr status

# View PR in browser
gh pr view --web
```

---

## Troubleshooting

### Tests fail unexpectedly

**Debug**:
```bash
# Run with verbose output
pytest -vv --tb=short

# Run single test
pytest tests/test_file.py::test_function_name -vv

# Check test database
python manage.py dbshell
```

### Linting errors

**Fix**:
```bash
# Auto-fix (Python)
ruff check --fix .
ruff format .

# Auto-fix (TypeScript)
pnpm lint --fix
```

### Migration conflicts

**Check**:
```bash
# Show migration status
python manage.py showmigrations

# If conflicts, resolve manually or reset (dev only)
```

---

## Checklist

- [ ] Task context loaded (task.yaml, SOPs, architecture docs)
- [ ] Feature branch created
- [ ] Tests written (RED state achieved)
- [ ] Feature implemented (GREEN state achieved)
- [ ] Code refactored
- [ ] All tests pass
- [ ] Linting passes
- [ ] Manual testing completed
- [ ] Documentation updated
- [ ] Changes committed with conventional commit message
- [ ] Branch pushed to remote
- [ ] Pull request created

---

## Related Documentation

- **TDD SOP**: `.agent/sops/SOP_TDD_SELF_HEALING_LOOP.md`
- **Git Workflow**: `.agent/sops/THE_COMPLETE_GIT_WORKFLOW.md`
- **Troubleshooting**: `.claude/reference/TROUBLESHOOTING.md`

---

**Last Updated**: 2025-10-28
**Maintained By**: Joel Schaeffer + Claude Code
