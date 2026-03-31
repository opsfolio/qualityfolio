if (evData) {
    // Normalize Date (DD-MM-YYYY to YYYY-MM-DD)
    let eDate =
        evData["cycle-date"] ||
        evData.date ||
        new Date().toISOString().split("T")[0];
    if (eDate.match(/^\d{2}-\d{2}-\d{4}$/)) {
        const [d, m, y] = eDate.split("-");
        eDate = `${y}-${m}-${d}`;
    }

    // Normalize Status (Title Case)
    let eStatus = evData.status || "To-do";
    eStatus =
        eStatus.charAt(0).toUpperCase() +
        eStatus.slice(1).toLowerCase();

    currentCase.evidenceHistory.push({
        cycle: evData.cycle || "1.0",
        cycleDate: eDate,
        status: eStatus,
        assignee: evData.assignee || "Unassigned",
    });
}