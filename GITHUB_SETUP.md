# GitHub Setup Guide

This guide will help you push the SwasthyaAI application to GitHub.

## Step 1: Create a GitHub Repository

1. Go to [GitHub](https://github.com)
2. Click the "+" icon in the top right corner
3. Select "New repository"
4. Fill in the details:
   - **Repository name**: `swasthyaai` (or your preferred name)
   - **Description**: "AI-Powered Clinical Intelligence Assistant"
   - **Visibility**: Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click "Create repository"

## Step 2: Initialize Git in Your Local Project

Open PowerShell or Command Prompt in your project directory and run:

```powershell
# Initialize git repository
git init

# Add all files to staging
git add .

# Create initial commit
git commit -m "Initial commit: SwasthyaAI Healthcare Platform"
```

## Step 3: Connect to GitHub Repository

Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual GitHub username and repository name:

```powershell
# Add remote repository
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Verify remote was added
git remote -v
```

## Step 4: Push to GitHub

```powershell
# Push to main branch
git branch -M main
git push -u origin main
```

If you're prompted for credentials:
- **Username**: Your GitHub username
- **Password**: Use a Personal Access Token (not your GitHub password)

### Creating a Personal Access Token (if needed)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name (e.g., "SwasthyaAI")
4. Select scopes: `repo` (full control of private repositories)
5. Click "Generate token"
6. Copy the token and use it as your password when pushing

## Step 5: Verify Upload

1. Go to your GitHub repository URL
2. Refresh the page
3. You should see all your files uploaded

## Alternative: Using GitHub Desktop

If you prefer a GUI:

1. Download and install [GitHub Desktop](https://desktop.github.com/)
2. Open GitHub Desktop
3. Click "Add" → "Add Existing Repository"
4. Browse to your project folder
5. Click "Publish repository"
6. Choose visibility (Public/Private)
7. Click "Publish repository"

## Important Notes

### Files That Will NOT Be Uploaded (due to .gitignore)

- `node_modules/` folders
- `.env` files (contains sensitive data)
- `function.zip` files
- Terraform state files
- Build outputs (`dist/`, `build/`)
- IDE settings (`.vscode/`, `.idea/`)

### Sensitive Information

**NEVER commit these files:**
- `.env` files with API keys
- AWS credentials
- Terraform `.tfvars` files with sensitive data
- Private keys or certificates

If you accidentally commit sensitive data:
1. Remove it immediately
2. Rotate all exposed credentials
3. Use `git filter-branch` or BFG Repo-Cleaner to remove from history

## Updating Your Repository

After making changes:

```powershell
# Check status
git status

# Add changed files
git add .

# Or add specific files
git add frontend/src/App.tsx

# Commit changes
git commit -m "Description of changes"

# Push to GitHub
git push
```

## Creating Branches

For new features:

```powershell
# Create and switch to new branch
git checkout -b feature/new-feature-name

# Make your changes, then commit
git add .
git commit -m "Add new feature"

# Push branch to GitHub
git push -u origin feature/new-feature-name
```

Then create a Pull Request on GitHub to merge into main.

## Common Git Commands

```powershell
# View commit history
git log

# View current branch
git branch

# Switch branches
git checkout branch-name

# Pull latest changes
git pull

# View differences
git diff

# Undo changes (before commit)
git checkout -- filename

# Undo last commit (keep changes)
git reset --soft HEAD~1
```

## Troubleshooting

### Error: "remote origin already exists"
```powershell
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
```

### Error: "failed to push some refs"
```powershell
# Pull first, then push
git pull origin main --rebase
git push origin main
```

### Large Files Error
If you get an error about large files:
1. Check which files are large: `git ls-files -s | sort -k 5 -n -r | head -10`
2. Add them to `.gitignore`
3. Remove from git: `git rm --cached large-file.zip`
4. Commit and push again

## Next Steps

After pushing to GitHub:

1. **Add a LICENSE file** (if you want to specify licensing)
2. **Enable GitHub Actions** for CI/CD (optional)
3. **Add branch protection rules** (for main branch)
4. **Create issues** for tracking bugs and features
5. **Add collaborators** (if working in a team)

## Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)
