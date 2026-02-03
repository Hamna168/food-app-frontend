# ---------- CONFIG ----------
$baseHref = "/food-chatbot-frontend/"  # Change to your GitHub Pages repo path
$indexPath = "web\index.html"
$buildPath = "build\web\*"
$destPath = ".\"
$branch = "gh-pages"
# ----------------------------

function Commit-If-Changes($message) {
    # Check if there are any changes
    $status = git status --porcelain
    if ($status) {
        git add .
        git commit -m $message
    } else {
        Write-Host "✅ No changes to commit."
    }
}

# Step 1: Commit any Flutter code changes first
$codeTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
Commit-If-Changes "Code changes before deploy $codeTimestamp"

# Step 2: Update base href for GitHub Pages
(Get-Content $indexPath) -replace '<base href="\$FLUTTER_BASE_HREF">', "<base href=`"$baseHref`">" | Set-Content $indexPath

# Step 3: Clean previous builds
flutter clean

# Step 4: Build Flutter Web
flutter build web

# Step 5: Copy build files to repo root safely
Copy-Item -Recurse -Force $buildPath $destPath

# Step 6: Commit deployment
$deployTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
Commit-If-Changes "Deploy Flutter Web $deployTimestamp"

# Step 7: Push to GitHub Pages branch
git push origin $branch
