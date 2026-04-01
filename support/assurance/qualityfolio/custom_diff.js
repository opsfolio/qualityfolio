document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('code.language-diff').forEach(block => {
        // We use textContent to avoid double-processing HTML entities if any
        // But since we want to insert spans, we split the innerHTML.
        const lines = block.innerHTML.split('\n');
        const highlighted = lines.map(line => {
            // Be careful to check the first character, considering it might start with a span if already processed,
            // or if it has HTML entities. SQLPage will escape < and > so line might be plain text.
            const textContent = parseHTML(line).trim();
            if (line.startsWith('+') || line.startsWith(' +') || line.startsWith('<span class="token">+')) {
                return '<span class="diff-addition">' + line + '</span>';
            } else if (line.startsWith('-') || line.startsWith(' -') || line.startsWith('<span class="token">-')) {
                return '<span class="diff-deletion">' + line + '</span>';
            } else if (line.startsWith('@@')) {
                return '<span class="diff-meta">' + line + '</span>';
            }
            return line;
        });
        block.innerHTML = highlighted.join('\n');
    });

    function parseHTML(html) {
        var t = document.createElement('template');
        t.innerHTML = html;
        return t.content.textContent || "";
    }
});
