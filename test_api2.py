import requests
import json
url = 'https://educaysoft.org/sica/index.php/alimentacion/alimentacion_personaflutter'
for i in [1, 2, 3, 118, 125]:
    res = requests.post(url, data={'idpersona': str(i)})
    data = res.json()
    if data.get('data'):
        print(f"idpersona {i}: {json.dumps(data['data'][0], indent=2)}")
        break
