function canPlayerFillSlot(playerPos, slotPos) {
    for (const option of slotPos.split('/')) {
        if (new RegExp(`\\b${option}\\b`).test(playerPos)) return true;
    }
    return false;
}

function isLineUpFilled(lineUp, players) {
    // Build adjacency list: for each slot, list of player indices that can fill it
    const adj = lineUp.map(slot =>
        players.reduce((acc, p, pi) => { if (canPlayerFillSlot(p, slot)) acc.push(pi); return acc; }, [])
    );

    // Augmenting path bipartite matching
    const matchPlayer = new Array(players.length).fill(-1);

    function augment(slotIdx, visited) {
        for (const pi of adj[slotIdx]) {
            if (visited[pi]) continue;
            visited[pi] = true;
            if (matchPlayer[pi] === -1 || augment(matchPlayer[pi], visited)) {
                matchPlayer[pi] = slotIdx;
                return true;
            }
        }
        return false;
    }

    let matched = 0;
    for (let i = 0; i < lineUp.length; i++) {
        if (augment(i, new Array(players.length).fill(false))) matched++;
    }

    return matched === lineUp.length;
}

function getFilledFormations(formations, teamComposition) {
    const filledFormations = {};

    for (let formation in formations) {
        filledFormations[formation] = {
            lineUp: isLineUpFilled(formations[formation].lineUp, teamComposition),
            lineUpWithReserve: isLineUpFilled(formations[formation].lineUpWithReserve, teamComposition)
        };
    }

    return filledFormations;
}
