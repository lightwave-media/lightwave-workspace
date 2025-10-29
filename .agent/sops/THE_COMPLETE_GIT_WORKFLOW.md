  🔄 The Complete Git Workflow

  📍 When Do You Create PRs?

  Simple Answer: Create a PR when you're ready for code review and want to merge your work.

  Detailed Flow:

  1. Start work → Create feature branch
  2. Write code → Commit to feature branch
  3. Code complete → Push feature branch
  4. Ready for review → Create PR (feature → dev)
  5. PR approved → Merge to dev
  6. Dev tested → Create PR (dev → prod)
  7. Prod approved → Merge to prod

  ---
  🎯 Step-by-Step: Feature Development

  Phase 1: Start Feature (No PR Yet)

  # 1. Start from dev branch
  cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/{your-repo}
  git checkout dev
  git pull origin dev

  # 2. Create feature branch (following your naming convention)
  git checkout -b feat/auth/LW-123-oauth-integration
  # Pattern: <type>/<domain>/<task-id>-<slug>

  # 3. Work on feature
  # - Write code
  # - Write tests
  # - Commit as you go

  git add .
  git commit -m "feat(auth): add OAuth provider configuration"

  # Keep committing...
  git commit -m "feat(auth): implement OAuth login flow"
  git commit -m "test(auth): add OAuth integration tests"

  No PR yet! You're just working on your feature branch.

  ---
  Phase 2: Ready for Review (Create PR to dev)

  # 4. Push your feature branch
  git push -u origin feat/auth/LW-123-oauth-integration

  # 5. NOW create PR: feature → dev
  gh pr create \
    --base dev \
    --head feat/auth/LW-123-oauth-integration \
    --title "[FEAT] Add OAuth integration to auth system" \
    --assignee "@me" \
    --label "feature,auth"

  At this point:
  - ✅ PR created: feat/auth/LW-123-oauth-integration → dev
  - 🔍 PR is open for review
  - ⏳ Waiting for approval
  - ❌ NO PR to prod yet!

  ---
  Phase 3: Merge to Dev (Automatic Deployment)

  # 6. After PR approval, merge to dev
  gh pr merge <PR-NUMBER> --squash --delete-branch

  # Or merge via GitHub UI

  What happens automatically:
  - ✅ Your branch merges into dev
  - ✅ GitHub Actions runs tests
  - ✅ If tests pass → Auto-deploys to dev environment
  - ✅ Feature branch deleted
  - ❌ Still NO PR to prod!

  Important: Merging to dev does NOT automatically create a PR to prod. You control when that happens.

  ---
  Phase 4: Testing in Dev Environment

  # 7. Test your feature in dev environment
  # - Manual testing
  # - QA review
  # - Stakeholder approval
  # - Integration testing with other features

  No git commands needed here - just testing the deployed dev environment.

  ---
  Phase 5: Ready for Production (Create PR to prod)

  # 8. When ALL features in dev are tested and ready
  cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/{your-repo}
  git checkout dev
  git pull origin dev

  # 9. NOW create PR: dev → prod
  gh pr create \
    --base prod \
    --head dev \
    --title "[RELEASE] Deploy features X, Y, Z to production" \
    --body "$(cat <<'EOF'
  ## Features Included
  - OAuth integration (LW-123)
  - Payment webhooks (LW-124)
  - Email notifications (LW-125)

  ## Testing Completed
  - [x] All tests passing in dev
  - [x] Manual QA complete
  - [x] Stakeholder approval
  - [x] Performance tested

  ## Deployment Plan
  1. Merge to prod
  2. GitHub Actions builds production image
  3. ECS Fargate deploys to production
  4. Monitor logs and metrics

  Requires manual approval before merge.
  EOF
  )" \
    --assignee "@me" \
    --label "release,production"

  At this point:
  - ✅ PR created: dev → prod
  - ⏳ Awaiting manual approval (you or team lead)
  - ❌ NOT merged yet!

  ---
  Phase 6: Deploy to Production (Manual Approval)

  # 10. After approval, merge to prod
  gh pr merge <PR-NUMBER> --merge
  # Use --merge (not --squash) to preserve all dev commits

  What happens:
  - ✅ dev branch merges into prod
  - ✅ GitHub Actions runs production deployment
  - ✅ Deploys to AWS ECS Fargate (production)
  - ✅ Production is now updated

  ---
  🔁 Visual Flow Diagram

  ┌─────────────────────────────────────────────────────────────┐
  │ 1. START: Create feature branch from dev                    │
  │    git checkout -b feat/auth/LW-123-oauth                   │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 2. WORK: Write code, commit, push                           │
  │    git commit -m "feat(auth): ..."                          │
  │    git push origin feat/auth/LW-123-oauth                   │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 3. CREATE PR: feature → dev                                 │
  │    gh pr create --base dev --head feat/auth/LW-123-oauth    │
  │    [FEAT] Add OAuth integration                             │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 4. REVIEW: Code review, approval                            │
  │    Team reviews PR, approves                                │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 5. MERGE TO DEV: Automatic deployment                       │
  │    gh pr merge --squash --delete-branch                     │
  │    ✅ GitHub Actions → Deploys to dev environment           │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 6. TEST: QA in dev environment                              │
  │    Manual testing, integration testing                      │
  │    Wait for all features to be ready                        │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 7. CREATE PR: dev → prod (MANUAL STEP)                      │
  │    gh pr create --base prod --head dev                      │
  │    [RELEASE] Deploy features X, Y, Z to production          │
  │    ⚠️  YOU control when this happens                        │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 8. APPROVE: Manual approval required                        │
  │    Review PR, verify all tests pass, approve                │
  └─────────────────────┬───────────────────────────────────────┘
                        │
                        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ 9. MERGE TO PROD: Production deployment                     │
  │    gh pr merge --merge                                      │
  │    ✅ GitHub Actions → Deploys to AWS ECS Fargate (prod)    │
  └─────────────────────────────────────────────────────────────┘

  ---
  ❓ Your Specific Questions Answered

  Q: "Do I create PRs at the beginning of a feature/bug/patch?"

  A: No! Create PRs when you're ready to merge.

  Timeline:
  Day 1: Start feature → Create branch (NO PR)
  Day 2: Write code → Commit to branch (NO PR)
  Day 3: Code complete → Push branch → CREATE PR (feature → dev)
  Day 3: PR reviewed → Merge to dev
  Day 4-7: Test in dev environment (NO PR to prod yet)
  Day 8: All features ready → CREATE PR (dev → prod)
  Day 8: PR approved → Merge to prod

  ---
  Q: "When I merge branches back to dev, does that automatically create a PR to prod?"

  A: NO! Absolutely not.

  What happens when you merge to dev:
  - ✅ Feature merges into dev branch
  - ✅ Auto-deploys to dev environment
  - ❌ Nothing happens to prod!

  You MANUALLY create the PR from dev → prod when ready.

  ---
  Q: "Do I wait until everything passes, then create PR to prod?"

  A: YES! Exactly right.

  The flow:

  # Multiple features merge to dev over time
  git checkout dev
  git merge feat/auth/oauth      # Feature 1 → dev
  git merge feat/billing/stripe  # Feature 2 → dev
  git merge fix/email/templates  # Bug fix → dev

  # All of these deploy to dev automatically

  # After testing ALL of them in dev:
  gh pr create --base prod --head dev   # NOW create PR to prod

  Wait until:
  - ✅ All features tested in dev
  - ✅ All tests passing
  - ✅ QA approval
  - ✅ Stakeholder approval
  - ✅ Ready for production

  Then: Create PR from dev → prod

  ---
  🎯 Best Practices

  1. Feature Branches (Short-Lived)

  # Good: Focused, merge quickly
  feat/auth/LW-123-oauth-integration  # 1-3 days, then merge

  # Bad: Long-lived, conflicts
  feat/auth/complete-rewrite          # 2 weeks, merge conflicts hell

  Rule: Keep feature branches short-lived (1-5 days). Merge to dev frequently.

  ---
  2. Dev Branch (Integration)

  # dev is where features combine
  feat/auth/oauth → dev     # Monday
  feat/billing/stripe → dev # Tuesday  
  fix/email/bug → dev       # Wednesday

  # Test all together in dev environment
  # When stable → promote to prod

  Rule: dev is always deployable but may have unstable features being tested.

  ---
  3. Prod Branch (Releases)

  # Prod gets updates in batches
  dev → prod  # Weekly release (Friday)
  dev → prod  # Hotfix (emergency only)

  Rule: prod only gets updates when dev is fully tested and approved.

  ---
  📋 PR Checklist

  PR from feature → dev

  ## Checklist
  - [ ] Code complete
  - [ ] Tests written (100% coverage)
  - [ ] Tests passing locally
  - [ ] No breaking changes (or documented)
  - [ ] Updated documentation
  - [ ] Ready for dev environment testing

  PR from dev → prod

  ## Checklist
  - [ ] All features tested in dev
  - [ ] All tests passing in CI
  - [ ] QA approval obtained
  - [ ] Stakeholder approval
  - [ ] No critical bugs in dev
  - [ ] Deployment plan documented
  - [ ] Rollback plan ready
  - [ ] Monitoring configured

  ---
  🚨 Common Mistakes to Avoid

  ❌ Mistake 1: Creating PR too early

  # Wrong
  git checkout -b feat/auth/oauth
  git commit -m "WIP: starting OAuth"
  gh pr create --base dev --head feat/auth/oauth  # Too early!

  Why bad: PRs create noise. Create when ready to merge.

  ---
  ❌ Mistake 2: Merging to prod without testing

  # Wrong
  git checkout dev
  git merge feat/auth/oauth
  gh pr create --base prod --head dev  # No testing!
  gh pr merge  # Deploy to prod immediately! 💥

  Why bad: Production breaks. Always test in dev first.

  ---
  ❌ Mistake 3: Forgetting to create prod PR

  # Wrong
  # Features pile up in dev forever
  # Prod never gets updates

  Why bad: Dev diverges from prod. Schedule regular releases.

  ---
  🎯 Recommended Workflow

  Daily: Feature Development

  # Morning: Start feature
  git checkout dev
  git pull origin dev
  git checkout -b feat/auth/LW-123-oauth

  # During day: Code
  git commit -m "feat(auth): ..."

  # End of day: Push
  git push origin feat/auth/LW-123-oauth

  # When complete: Create PR to dev
  gh pr create --base dev --head feat/auth/LW-123-oauth

  ---
  Weekly: Production Release

  # Friday: Review dev
  git checkout dev
  git pull origin dev

  # Create release PR
  gh pr create --base prod --head dev \
    --title "[RELEASE] Week 43 - OAuth, Billing, Email fixes"

  # After approval: Merge to prod
  gh pr merge <PR-NUMBER> --merge

  ---
  💡 TL;DR

  When to create PRs:
  1. feature → dev: When code is complete and ready for review
  2. dev → prod: When dev is tested and ready for production

  Automatic deployments:
  - ✅ Merge to dev → Auto-deploys to dev environment
  - ❌ Merge to dev → Does NOT create PR to prod

  Manual steps:
  - 🖐️ You create PR from dev → prod when ready
  - 🖐️ You approve and merge prod PR

  The key: Joel control's production releases. Dev → prod PRs are manual and intentional.
