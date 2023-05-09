---
title: Tutorial
layout: page
---
# Write Faasten Functions
Let's use `gen-thumb` in Python as an example as we consider that `gen-thumb` is very representative. We expect
typical FaaS functions to have the structure of download-compute-upload.

### Part 0: create `workload.py`
Assume we are in `gen-thumb` directory, our code goes into a single file `workload.py`.
Faasten supports multi-file function sources but always only explicitly load `workload.py`.

### Part 1: define the entry-point function `handle`.
Each function *must* define the entry-point function `handle`. The function takes two
positional arguments. The first is a Python object that contains all inputs. The second is the
CloudCall object whose methods are CloudCall wrappers. The function must return a JSON-serializable
object.

```python
# import dependencies
from PIL import Image
from io import BytesIO

def handle(event, cloudcall):
    return {}
```

### Part 2: make cloudcalls to download input data/upload output data
Download the input photo blob from the persistent storage
```python
download_path = event['input']
with cloudcall.fs_openblob(download_path) as blob:
    # compute over the blob and output to local storage ...
```

Upload the thumbnail to the persistent storage
```python
upload_path = ... # construct the upload path
with cloudcall.create_blob(upload_path) as newblob:
    newblob.finalize(data)
```

Detailed CloudCall documentations are [here](documentation/index).

### Part 3: main logic & everything together
```python
from PIL import Image
from io import BytesIO

def handle(event, cloudcall):
    download_path = event['input']
    output_dir = event['output_dir']
    sizes = event['sizes']
    with cloudcall.fs_openblob(download_path) as blob:
        img = Image.open(blob)
        for size in sizes:
            img.thumbnail(tuple(size))
            buff = BytesIO()
            img.save(buff, format='JPEG')
            thumnail_name = '-'.join(size) + '.jpeg'
            upload_path = ':'.join([output_dir, thumbnail_name])
            with cloudcall.create_blob(upload_path) as newblob:
                newblob.finalize(buff.getvalue())
   return {}
```

## Package `gen-thumb` Locally
Currently, Faasten relies on developers to package their functions into a Linux file-system
(we have used Ext2 and SquashFS).

### Package Dependencies
Docker is used to package native dependencies. A language's package installer is used to package
language dependencies (pip for Python). Lastly, a file-system formatter is required (mkfs or gensquashfs).

### Dependencies
TBD

## Register `gen-thumb`  using fstn
TBD

## Invoke `gen-thumb` using fstn
### Pre-upload a photo
TBD
