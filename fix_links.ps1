
$dir = "C:\Users\SUNNY\Downloads\sandeep-portfolio-site"

# ─────────────────────────────────────────────
# Helper: replace text in file
# ─────────────────────────────────────────────
function Fix-File($filename, $replacements) {
    $path = Join-Path $dir $filename
    if (-not (Test-Path $path)) { Write-Host "  MISSING: $filename" -ForegroundColor Red; return }
    $c = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    foreach ($r in $replacements) {
        $c = $c -replace [regex]::Escape($r[0]), $r[1]
    }
    [System.IO.File]::WriteAllText($path, $c, [System.Text.Encoding]::UTF8)
    Write-Host "  Fixed: $filename" -ForegroundColor Green
}

# ─────────────────────────────────────────────
# Universal nav-link fixer using regex (handles href="#" or missing href)
# Replaces nav anchor text with correct href
# ─────────────────────────────────────────────
function Fix-NavLinks($filename, $activePage) {
    $path = Join-Path $dir $filename
    if (-not (Test-Path $path)) { Write-Host "  MISSING: $filename" -ForegroundColor Red; return }
    $c = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

    # Fix nav links by text content - replace href values for known pages
    $navMap = @{
        '>Home<'    = 'index.html'
        '>About<'   = 'about.html'
        '>Works<'   = 'works.html'
        '>Resume<'  = 'resume.html'
        '>Contact<' = 'contact.html'
        '>Skills<'  = 'skills.html'
    }

    foreach ($entry in $navMap.GetEnumerator()) {
        $text = $entry.Key
        $href = $entry.Value
        # Match <a ...> with the given text, replace/add href
        $c = [regex]::Replace($c, '(<a[^>]*?)(?:\s+href="[^"]*")?((?:[^>]*?)' + [regex]::Escape($text) + ')', {
            param($m)
            $before = $m.Groups[1].Value
            $after  = $m.Groups[2].Value
            if ($before -match 'href=') {
                $before = $before -replace 'href="[^"]*"', "href=`"$href`""
            } else {
                $before = $before + " href=`"$href`""
            }
            return $before + $after
        })
    }

    [System.IO.File]::WriteAllText($path, $c, [System.Text.Encoding]::UTF8)
    Write-Host "  Nav fixed: $filename" -ForegroundColor Green
}

Write-Host "`n=== FIXING NAVIGATION LINKS ===" -ForegroundColor Yellow

$allPages = @("index.html","about.html","works.html","resume.html","contact.html","marrow-find.html","skills.html","achievements.html","404.html")
foreach ($page in $allPages) { Fix-NavLinks $page $page }

Write-Host "`n=== FIXING CTA BUTTONS & SPECIAL LINKS ===" -ForegroundColor Yellow

# ── index.html (Home) ──
Fix-File "index.html" @(
    @('href="/works"',    'href="works.html"'),
    @('href="/contact"',  'href="contact.html"'),
    @('href="/about"',    'href="about.html"'),
    @('href="/resume"',   'href="resume.html"'),
    @('href="/"',         'href="index.html"')
)

# ── about.html ──
Fix-File "about.html" @(
    @('href="/works"',    'href="works.html"'),
    @('href="/contact"',  'href="contact.html"'),
    @('href="/resume"',   'href="resume.html"'),
    @('href="/"',         'href="index.html"')
)

# ── works.html ──
Fix-File "works.html" @(
    @('href="/contact"',  'href="contact.html"'),
    @('href="/about"',    'href="about.html"'),
    @('href="/resume"',   'href="resume.html"'),
    @('href="/"',         'href="index.html"'),
    # Marrow-Find project detail link
    @('href="/marrow-find"', 'href="marrow-find.html"'),
    @('href="/projects/marrow-find"', 'href="marrow-find.html"')
)

# ── contact.html ──
Fix-File "contact.html" @(
    @('href="/resume"',       'href="resume.html"'),
    @('href="resume.html"',   'href="resume.html"'),   # already correct
    @('href="/works"',        'href="works.html"'),
    @('href="/about"',        'href="about.html"'),
    @('href="/"',             'href="index.html"')
)

# ── resume.html ──
Fix-File "resume.html" @(
    @('href="/contact"',  'href="contact.html"'),
    @('href="/works"',    'href="works.html"'),
    @('href="/"',         'href="index.html"')
)

# ── marrow-find.html ──
Fix-File "marrow-find.html" @(
    @('href="/works"',    'href="works.html"'),
    @('href="/contact"',  'href="contact.html"'),
    @('href="/"',         'href="index.html"')
)

# ── skills.html ──
Fix-File "skills.html" @(
    @('href="/works"',    'href="works.html"'),
    @('href="/contact"',  'href="contact.html"'),
    @('href="/"',         'href="index.html"')
)

# ── achievements.html ──
Fix-File "achievements.html" @(
    @('href="/works"',    'href="works.html"'),
    @('href="/contact"',  'href="contact.html"'),
    @('href="/resume"',   'href="resume.html"'),
    @('href="/"',         'href="index.html"')
)

# ── 404.html ──
Fix-File "404.html" @(
    @('href="/"',      'href="index.html"'),
    @('href="/works"', 'href="works.html"')
)

Write-Host "`n=== VERIFYING LINKS ===" -ForegroundColor Yellow
foreach ($page in $allPages) {
    $path = Join-Path $dir $page
    $c = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $links = [regex]::Matches($c, 'href="([^"#][^"]*\.html)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    Write-Host "`n[$page]" -ForegroundColor Cyan
    if ($links.Count -eq 0) { Write-Host "  (no .html links)" -ForegroundColor DarkYellow }
    else { $links | ForEach-Object { 
        $exists = Test-Path (Join-Path $dir $_)
        $status = if ($exists) { "OK" } else { "BROKEN" }
        $color  = if ($exists) { "Green" } else { "Red" }
        Write-Host "  $_ [$status]" -ForegroundColor $color
    }}
}

Write-Host "`n✅ Done! All links fixed." -ForegroundColor Green
