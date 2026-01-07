function Expand-ContextString {
    param (
        $context,
        [string]$template
    )

    $pattern = '\{([^}]+)\}'

    return [regex]::Replace(
        $template,
        $pattern,
        [System.Text.RegularExpressions.MatchEvaluator] {
            param($match)

            $path = $match.Groups[1].Value
            $value = $context

            foreach ($segment in $path -split '\.') {
                if ($null -eq $value) {
                    return ''
                }
                $value = $value.$segment
            }

            return [string]$value
        }
    )
}
