"""Fetch immutable OFL font assets at build time, verifying Git blob hashes."""
from pathlib import Path
from hashlib import sha1
from urllib.request import urlopen
from urllib.parse import quote
root=Path('assets/fonts')
root.mkdir(parents=True,exist_ok=True)
rev='06bfe0d62a98375cb09c942fa18e68bd32cff057'
files={
 'Outfit.ttf':('outfit/Outfit[wght].ttf','466d6245f9582df39bf73da91a8b3c938fd061cd'),
 'Inter.ttf':('inter/Inter[opsz,wght].ttf','047c92f6e2212473dc436020afed689527076d44'),
 'Outfit-OFL.txt':('outfit/OFL.txt','723cd447edee83ed3bb07c3343f478d352aa7440'),
 'Inter-OFL.txt':('inter/OFL.txt','21f6aff961064c2e429f570995e446bcdd555422'),
}
def digest(data):
    return sha1(('blob %d\0'%len(data)).encode()+data).hexdigest()
for name,(source,expected) in files.items():
    path=root/name
    if path.exists() and digest(path.read_bytes())==expected:
        continue
    url='https://raw.githubusercontent.com/google/fonts/'+rev+'/ofl/'+quote(source,safe='/')
    with urlopen(url,timeout=45) as r:
        data=r.read(2_000_000)
    if digest(data)!=expected:
        raise ValueError('Font checksum mismatch: '+name)
    path.write_bytes(data)
