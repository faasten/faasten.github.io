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
cargo install --git https://github.com/faasten/fstn.git --branch tutorial fstn
```
Faasten log-in
```sh
# faasten server address
export FSTN_SERVER=https://sns60.cs.princeton.edu
# follow instructions, only Princeton CAS is supported as of now
fstn login
```

# End-User-Oriented Privilege Management
The tutorial code include a function image `thumbnail.img`.
Now, install the image to your home directory on Faasten.
```sh
export FSTN_SERVER=https://sns60.cs.princeton.edu
export NETID=yuetan # replace with your NETID
# in example-apps/tutorial
fstn register ./thumbnail.img $NETID/tutorial/thumb,$NETID/tutorial/thumb '~:thumbnail' 128 python
```
Check your home directory. The installment should create the entry `thumbnail`.
```sh
fstn list-dir '~'
```
Test out the installment.
```sh
# set up the photo blob
fstn put-blob ./people12.jpg '~:people12.jpg' $NETID,$NETID
# invoke
echo '{"download_key":":home:<'$NETID,$NETID'>:people12.jpg", "output_dir":":home", "sizes":[[75,75],[100,100]]}' | fstn invoke '~:thumbnail'
# check the outputs, they should be in :home:<$NETID,$NETID/tutorial/thumb>
fstn list-dir ':home:<'$NETID,$NETID'/tutorial/thumb>'
# your home directory is untouched
fstn list-dir '~'
```

**Discussion**

(*Faasten tightly couples a file-system with the computation substrate. As a result, data are named by colon-separated
paths. In the example above, `:` names the root directory. `home` names a faceted directory in the root directory,
`<yuetan,yuetan>` names a facet of `home`.
A facet is a directory named by its security policy. In this case, the facet can be read by anyone but can only
be written by `yuetan`.*

*Notably, `~` is the shorthand of one's home directory `:home:<USER,USER>`, readable and writable
only by USER.*

*Gates are our mechanism to transfer a privilege in a protected way.
Functions are linked into the file-system as gates as invoking a function indirectly grants the invoker
some privilege.
Above, when we register `thumbnail`, the second positional argument is the policy specifying what privilege
we are granting---yuetan/tutorial/thumb (before the comma)---and the integrity that an invoker's integrity
must be as strong as---yuetan/tutorial/thumb (after the comma).
This policy would allow one thumbnail instance invokes another.*)

# System-Enforced End-to-End Data Security
Now let's try different output_dir values.

First, we can supply a value that leaks the presence of the thumbnails (metadata).
```sh
echo '{"download_key":":home:<'$NETID,$NETID'>:people12.jpg", "output_dir":":home:<T,'$NETID'/tutorial/thumb>", "sizes":[[75,75],[100,100]]}' | fstn invoke '~:thumbnail'
# check the leaky output dir, we will see that the invocation silently fails
fstn list-dir ':home:<T,'$NETID'/tutorial/thumb>'
```
Next, we can supply a value that the instance cannot write.
```sh
echo '{"download_key":":home:<'$NETID,$NETID'>:people12.jpg", "output_dir":":home:<'$NETID,$NETID'>", "sizes":[[75,75],[100,100]]}' | fstn invoke '~:thumbnail'
# check the non-writable output dir, we will see that the invocation silently fails
fstn list-dir ':home:<'$NETID,$NETID'>'
```

**Discussion**

(*In Faasten, data security is enforced by the system end-to-end. Here, the photo blob itself and its
presence are both private to the end user (i.e. the owner). The system enforce that any function that
reads the photo blob cannot output to a less secret location unless the function acts on behalf of
the end user (i.e. runs with the privilege $NETID) and can, therefore, declassify its computation.*

*The photo blob and its presence are also only writable by the end user (or the owner). This makes sure
that no function can delete the photo or point the name to something else unless it acts on behalf of
the end user.*)


# Add Functionalities
By design, in Faasten, one can easily extend an application without breaking the security.
As a prompt, the tutorial code includes `detect-face/workload.py` an incomplete source of the function
that add the face detection functionality.

### Learn to Write Faasten Functions
First, let's dive into the source of `thumbnail` to see how a faasten looks like.

#### 0. `workload.py` and the entry-point function `handle`.
Faasten loads a function as a module through explicitly loading `workload.py`. That is, a function's
source should always include the `workload.py` file.

Additionally, each function *must* define the entry-point function `handle` inside `workload.py`.
The function takes two positional arguments. The first is a Python object that contains all inputs.
The second is the CloudCall object whose methods are CloudCall wrappers. The function must return a JSON-serializable
object.

```python
# import dependencies
from PIL import Image

def handle(event, cloudcall):
    return {}
```

#### 1. make cloudcalls to download input data/upload output data
Download the input photo blob from the persistent storage.
```python
download_path = event['input']['download_key']
with cloudcall.fs_openblob(download_path) as blob:
    # compute over the blob and output to local storage ...
```

Upload the thumbnail to the persistent storage.
```python
upload_path = ... # construct the upload path
with cloudcall.create_blob() as newblob:
    bn = img.save(newblob, format='JPEG')
    newblob.finalize(b'')
    cloudcall.fs_linkblob(upload_path, bn)
```

Detailed CloudCall documentations are [here](documentation/index) (wip).

#### 2. computation & everything together
```python
from PIL import Image

def handle(event, cloudcall):
    download_path = event['input']['download_key']
    output_dir = event['input']['output_dir']
    sizes = event['input']['sizes']
    blobs = {}
    with cloudcall.fs_openblob(download_path) as blob:
        img = Image.open(blob)
        for size in sizes:
            img.thumbnail(tuple(size))
            thumbnail_name = '-'.join(map(str, size)) + '.jpeg'
            upload_path = ':'.join([output_dir, thumbnail_name])
            with cloudcall.create_blob() as newblob:
                img.save(newblob, format='JPEG')
                bn = newblob.finalize(b'')
                blobs[thumbnail_name] = bn
                cloudcall.fs_linkblob(upload_path, bn)
    return {'thumb-blobs': blobs}
```

### Task: complete `detect-face/workload.py`
`detect-face` has the same structure as `thumbnail`---download the input, compute, and upload the result.
Just like `thumbnail`, the system will automatically confines an `detect-face` instance.
