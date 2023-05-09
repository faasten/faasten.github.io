---
layout: home
---
# What is Faasten?
Faasten is a research Function-as-a-Service (FaaS) system. Faasten advocates that to solve the problem
of securing end-user data in FaaS applications,
the FaaS system should offer coherent end-user-oriented security assurances.

# Motivating Example: Photo Management
The end-to-end security assurance that Alice's private photo and its derived data (thumbnails) or metadata (the time index)
stay private to Alice should be easy to achieve. Sharing should be possible through explicit requests.

![photo management](assets/images/pma.png){: width="50%"}
*Thumbnail and time index generation for each uploaded photo. A photo can be marked as sharable.*

# Design Overview
Faasten defines a distributed *cloud kernel* architecture that
abstracts the network and the persistent storage and enforces *information flow control*
(IFC).

![the distributed cloud kernel architecture](assets/images/distributed-cloud-kernel.jpeg)

Concretely, the abstraction is a file-system Faasten-FS. Faasten-FS consists of files, blobs, directories,
faceted directories, gates, and services. Data are files (mutable) and blobs (immutable). Metadata (data discovery
and data security policies) are directories and faceted directories. Privilege transfers (invoking another function
and accessing the network) are gates and services.

![cloudcall vs boto3](assets/images/cloudcall-vs-boto3.png){: width="50%"}
*Functions make CloudCalls to call into the cloud kernel, removing ad-hoc security checks in non-Faasten
FaaS applications*

(Note that *the cloud kernel simply offers invocation functionality and does not
consider scheduling-related security concerns.*)

# Tutorial: Write, Register and Invoke a Faasten Function
The following tutorial uses `gen-thumb` as an example to demonstrate how to write, register and
invoke a Faasten function.

## Write `gen-thumb`
Assume we are in `gen-thumb` directory, our code goes into a single file `workload.py`.
Faasten support multi-file function sources but always only explicitly load `workload.py`.

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

## Packaging `gen-thumb` Locally
Currently, Faasten relies on developers to package their functions into a Linux file-system
(we have used Ext2 and SquashFS).

### Prerequisites
If the function has any dependencies, Docker is required. Otherwise, only mkfs is required.

### Dependencies
TBD

## Register function using fstn
TBD
