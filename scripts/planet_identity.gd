extends RefCounted
## Orbital identities, independent of the four shared ground material families.
const PROFILES:=[
	{"id":"crystal","land":"8870b0","water":"248d9a","ridge":"d5c3eb","air":"82c9ee","cloud":"e4edff","sea":.48,"ice":.07,"coverage":.38,"seed":1.7,"moons":1,"rings":0},
	{"id":"garden","land":"44854c","water":"246d70","ridge":"a9c989","air":"84d4c3","cloud":"f3fff0","sea":.38,"ice":.02,"coverage":.69,"seed":4.1,"moons":0,"rings":0},
	{"id":"dunes","land":"c58c52","water":"684831","ridge":"efd3a0","air":"e0b78a","cloud":"efddbf","sea":.12,"ice":0.,"coverage":.14,"seed":7.8,"moons":2,"rings":1},
	{"id":"city","land":"344566","water":"142c50","ridge":"8295aa","air":"739bea","cloud":"cfdbfa","sea":.48,"ice":.04,"coverage":.28,"seed":10.3,"moons":1,"rings":0},
	{"id":"ocean","land":"659766","water":"228db8","ridge":"d1d4a3","air":"74cdef","cloud":"f2fbff","sea":.72,"ice":.04,"coverage":.56,"seed":13.9,"moons":2,"rings":0},
	{"id":"savanna","land":"9b9252","water":"546d68","ridge":"d9b16e","air":"ebd1a1","cloud":"fff2d7","sea":.29,"ice":.02,"coverage":.22,"seed":18.2,"moons":1,"rings":0},
	{"id":"mycelium","land":"455e63","water":"304658","ridge":"9c859f","air":"9bd9c4","cloud":"d7cfe3","sea":.3,"ice":0.,"coverage":.64,"seed":21.6,"moons":1,"rings":0},
	{"id":"ice","land":"bbcfdc","water":"2a668d","ridge":"ecf6ff","air":"b0dbf8","cloud":"e6f3ff","sea":.48,"ice":.78,"coverage":.22,"seed":25.1,"moons":2,"rings":2},
	{"id":"volcanic","land":"383337","water":"241f25","ridge":"805544","air":"c67c51","cloud":"827b79","sea":.08,"ice":0.,"coverage":.19,"seed":29.3,"moons":1,"rings":0},
	{"id":"anomaly","land":"46426b","water":"19253e","ridge":"a18bc2","air":"ab94dc","cloud":"a9add3","sea":.42,"ice":0.,"coverage":.24,"seed":33.7,"moons":0,"rings":2}
]
static func get_profile(index:int) -> Dictionary: return PROFILES[posmod(index,10)]
