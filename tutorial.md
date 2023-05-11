---
title: Tutorial
layout: page
---
In this tutorial, you will:
1. get to know how Faasten manages security privileges,
2. get to know Faasten's system-enforced data security,
2. get to know how one can easily add a functionality without breaking the security.

# Prerequisites
* [Rust](https://www.rust-lang.org/tools/install)

# Get Ready
Download the tutorial code.
```sh
git clone git@github.com:faasten/example-apps
cd example-apps/tutorial
```
Install Faasten's command line client `fstn` on your local machine
```sh
git clone git@github.com:faasten/fstn
cd fstn
git checkout tutorial
cargo install --path .
```
Faasten log-in
```sh
# follow instructions
fstn login
```

# Privilege Management: Install a Function on Faasten
We have already registered a thumbnail generation function at `:home:<T,yuetan>:thumbnail`.
Now, install the function to your home directory.
```sh
./install_thumbnail.sh
```
Check your home directory. The installment should create `~:thumbnail`.
```sh
fstn list-dir '~'
```
Test out the installment.
```sh
./test_thumbnail.sh
```

(*Faasten tightly couples a file-system with the computation substrate and data are named by colon-separated
paths. In the example above, `:` is the root directory. `home` is a faceted directory. `<T,yuetan>` names a facet of `home`.
A facet is a directory named by its security policy. In this example, the facet can be read by anyone but can only
be written by `yuetan`.*

*Furthermore, `~` is the shorthand of one's home directory `:home:<USER,USER>`, readable and writable
only by USER.*)

# System-Enforced Data Security: Try a Different Output Path

# Write New Functions that Add Functionalities
By design, in Faasten, one can easily extend an application without breaking the security.
In this section, you will write a new function `detect-face` that add the face detection functionality.

## Learn to Write Faasten Functions
First, let's dive into the source of `thumbnail` to see how a faasten looks like.

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

## Complete `face-detect/workload.py`

## Try out `face-detect`
