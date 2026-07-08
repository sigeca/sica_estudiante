import requests
url = 'https://educaysoft.org/sica/index.php/alimentacion/alimentacion_personaflutter'
res = requests.post(url, data={'idpersona': '44'})
print(res.text[:1000])
