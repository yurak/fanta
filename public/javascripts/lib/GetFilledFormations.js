/* eslint-disable */

const formations = {
    f343: {
        lineUp: ['Dc', 'Dc', 'Dc', 'E', 'E', 'M/C', 'C', 'W/A', 'W/A', 'A/Pc' ],
        lineUpWithReserve: ['Dc', 'Dc', 'Dc', 'E', 'E', 'M/C', 'C', 'W/A', 'W/A', 'A/Pc' , 'Dc', 'Dc', 'Dc', 'E', 'E', 'M/C', 'C', 'W/A', 'W/A', 'A/Pc'],
    },
    f3412: {
        lineUp: ['Dc', 'Dc', 'Dc', 'E', 'E', 'M/C', 'C', 'T', 'A/Pc', 'A/Pc' ],
        lineUpWithReserve: ['Dc', 'Dc', 'Dc', 'E', 'E', 'M/C', 'C', 'T', 'A/Pc', 'A/Pc', 'Dc', 'Dc', 'Dc', 'E', 'E', 'M/C', 'C', 'T', 'A/Pc', 'A/Pc' ],
    },
    f3421: {
        lineUp: ['Dc', 'Dc', 'Dc', 'E', 'E/W', 'M/C', 'M', 'T', 'T/A', 'A/Pc' ],
        lineUpWithReserve: ['Dc', 'Dc', 'Dc', 'E', 'E/W', 'M/C', 'M', 'T', 'T/A', 'A/Pc' , 'Dc', 'Dc', 'Dc', 'E', 'E/W', 'M/C', 'M', 'T', 'T/A', 'A/Pc']
    },
    f352: {
        lineUp: ['Dc', 'Dc', 'Dc', 'E', 'M', 'M/C', 'C', 'E/W', 'A/Pc', 'A/Pc' ] ,
        lineUpWithReserve: ['Dc', 'Dc', 'Dc', 'E', 'M', 'M/C', 'C', 'E/W', 'A/Pc', 'A/Pc' , 'Dc', 'Dc', 'Dc', 'E', 'M', 'M/C', 'C', 'E/W', 'A/Pc', 'A/Pc' ]
    },
    f3511: {
        lineUp: ['Dc', 'Dc', 'Dc', 'E/W', 'M', 'M', 'C', 'E/W', 'T/A', 'A/Pc' ],
        lineUpWithReserve: ['Dc', 'Dc', 'Dc', 'E/W', 'M', 'M', 'C', 'E/W', 'T/A', 'A/Pc', 'Dc', 'Dc', 'Dc', 'E/W', 'M', 'M', 'C', 'E/W', 'T/A', 'A/Pc' ]
    },
    f433: {
        lineUp: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'C', 'W/A', 'W/A', 'A/Pc' ],
        lineUpWithReserve: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'C', 'W/A', 'W/A', 'A/Pc', 'Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'C', 'W/A', 'W/A', 'A/Pc' ]
    },
    f4312: {
        lineUp: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'C', 'T', 'A/Pc', 'A/Pc' ],
        lineUpWithReserve: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'C', 'T', 'A/Pc', 'A/Pc', 'Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'C', 'T', 'A/Pc', 'A/Pc' ]
    },
    f442: {
        lineUp: ['Dc', 'Dc', 'Ds', 'Dd', 'E', 'M/C', 'C', 'E/W', 'A/Pc', 'A/Pc'],
        lineUpWithReserve: ['Dc', 'Dc', 'Ds', 'Dd', 'E', 'M/C', 'C', 'E/W', 'A/Pc', 'A/Pc', 'Dc', 'Dc', 'Ds', 'Dd', 'E', 'M/C', 'C', 'E/W', 'A/Pc', 'A/Pc']
    },
    f4141: {
        lineUp: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'E/W', 'C/T', 'T', 'W', 'A/Pc'],
        lineUpWithReserve: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'E/W', 'C/T', 'T', 'W', 'A/Pc', 'Dc', 'Dc', 'Ds', 'Dd', 'M', 'E/W', 'C/T', 'T', 'W', 'A/Pc']
    },
    f4411: {
        lineUp: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'E/W', 'C', 'E/W', 'T/A', 'A/Pc'],
        lineUpWithReserve: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'E/W', 'C', 'E/W', 'T/A', 'A/Pc', 'Dc', 'Dc', 'Ds', 'Dd', 'M', 'E/W', 'C', 'E/W', 'T/A', 'A/Pc']
    },
    f4231: {
        lineUp: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'W/T', 'T', 'A', 'A/Pc'],
        lineUpWithReserve: ['Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'W/T', 'T', 'A', 'A/Pc', 'Dc', 'Dc', 'Ds', 'Dd', 'M', 'M/C', 'W/T', 'T', 'A', 'A/Pc']
    },
};

function isLineUpFilled(lineUp, players) {
    let allPositionsFilled = true;

    for (let position of lineUp) {
        const possiblePositions = position.split('/');
        let found = false;

        for (let i = 0; i < possiblePositions.length; i++) {
            const playerPositions = players.filter(playerPosition => {
                const positionRegex = new RegExp(`\\b${possiblePositions[i]}\\b`);
                return positionRegex.test(playerPosition);
            });

            if (playerPositions.length > 0) {
                players.splice(players.indexOf(playerPositions[0]), 1);
                found = true;
                break;
            }
        }

        if (!found) {
            allPositionsFilled = false;
            for (let i = 0; i < possiblePositions.length; i++) {
                const player = players.filter(playerPosition => {
                    const positionRegex = new RegExp(`\\b${possiblePositions[i]}\\b`);
                    return positionRegex.test(playerPosition);
                });

                if (!player) {
                    allPositionsFilled = false;
                    break;
                }
            }
        }
    }

    return allPositionsFilled;
}

function getFilledFormations(teamComposition) {
    const sortTeamComposition = teamComposition.sort((a, b) => {
        const aHasExt = a.indexOf("/") > -1;
        const bHasExt = b.indexOf("/") > -1;
        return aHasExt - bHasExt;
    });

    const filledFormations = {};

    for (let formation in formations) {
        filledFormations[formation] = {
            lineUp: isLineUpFilled(formations[formation].lineUp, [...sortTeamComposition]),
            lineUpWithReserve: isLineUpFilled(formations[formation].lineUpWithReserve, [...sortTeamComposition])
        };
    }

    return filledFormations;
}
/* eslint-enable */
