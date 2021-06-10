p 'Create Tournaments'
Tournaments::Creator.call

p 'Create Positions'
Positions::Creator.call

p 'Create TeamModules with Slots'
Slots::Creator.call

p 'Create Season'
Season.find_or_create_by(start_year: Season::MIN_START_YEAR, end_year: Season::MIN_END_YEAR)
