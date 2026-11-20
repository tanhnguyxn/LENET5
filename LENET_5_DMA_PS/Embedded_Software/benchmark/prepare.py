"""Prepare datasets on a PC or the board using only Python's standard library."""
import argparse
import gzip
import struct
from pathlib import Path

layers = [('conv1',150,6),('conv2',2400,16),('fc1',30720,120),('fc2',10080,84),('fc3',840,10)]
blocks = [(name+'_'+kind, layer[i]) for kind,i in [('weight',1),('bias',2)]
          for layer in layers for name in [layer[0]]]

def words(path, count):
    values = [int(x,16) for x in path.read_text().split()]
    if len(values)!=count or any(not 0<=x<=65535 for x in values):
        raise ValueError(f'Wrong count or non-Q8.8 word: {path}')
    return [x if x<32768 else x-65536 for x in values]

def golden(image, p):
    # Same order as exported OIHW conv and output-major FC weights.
    x = image
    side = 28
    channels = 1
    def clip(v):
        return max(-32768,min(32767,v))
    for name,out_channels in [('conv1',6),('conv2',16)]:
        w,b = p[name+'_weight'],p[name+'_bias']
        width = side-4
        y = []
        for o in range(out_channels):
            plane = []
            for row in range(width):
                for col in range(width):
                    acc = b[o]
                    for c in range(channels):
                        for dy in range(5):
                            loc = (c*side+row+dy)*side+col
                            wi = ((o*channels+c)*5+dy)*5
                            acc += sum((x[loc+k]*w[wi+k])>>8 for k in range(5))
                    plane.append(max(0,clip(acc)))
            for row in range(0,width,2):
                for col in range(0,width,2):
                    j=row*width+col
                    y.append(max(plane[j],plane[j+1],plane[j+width],plane[j+width+1]))
        x,side,channels = y,width//2,out_channels
    for name in ['fc1','fc2','fc3']:
        w,b = p[name+'_weight'],p[name+'_bias']
        n=len(x)
        y=[clip(v+sum((a*z)>>8 for a,z in zip(x,w[i*n:(i+1)*n]))) for i,v in enumerate(b)]
        x=y if name=='fc3' else [max(0,v) for v in y]
    return x

def idx(root, name):
    path=root/name
    if path.is_file():
        return path.read_bytes()
    return gzip.decompress((root/(name+'.gz')).read_bytes())

def pack16(values):
    return struct.pack('<%dh'%len(values),*values)

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('hexdir',type=Path)
    ap.add_argument('out',type=Path)
    ap.add_argument('--mnist',type=Path,help='folder containing both t10k IDX files, raw or .gz')
    a=ap.parse_args()
    p={name:words(a.hexdir/(name+'.hex'),n) for name,n in blocks}
    A=words(a.hexdir/'sample_input.hex',784)
    ref=words(a.hexdir/'sample_logits.hex',10)
    if golden(A,p)!=ref:
        raise SystemExit('Sample reference and exported weights disagree. Check model export.')
    B=[256-v for v in A] if all(0<=v<=256 for v in A) else [0]*784
    refB=golden(B,p)
    if refB==ref:
        raise SystemExit('A and B have identical logits. Supply a different sample A.')
    a.out.mkdir(parents=True,exist_ok=True)
    def record(x,y):
        return pack16(x)+pack16(y)
    (a.out/'prep.bin').write_bytes(b'L5P1'+b''.join(pack16(p[n]) for n,_ in blocks)+record(A,ref)+record(B,refB))
    if a.mnist:
        im=idx(a.mnist,'t10k-images-idx3-ubyte')
        lab=idx(a.mnist,'t10k-labels-idx1-ubyte')
        if (struct.unpack('>4I',im[:16])!=(2051,10000,28,28) or
            struct.unpack('>2I',lab[:8])!=(2049,10000) or len(im)!=7840016 or
            len(lab)!=10008 or max(lab[8:])>9):
            raise ValueError('Invalid MNIST test set')
        lut=[round(v*256/255) for v in range(256)]
        with (a.out/'mnist.bin').open('wb') as f:
            f.write(b'L5M1')
            for i,label in enumerate(lab[8:]):
                f.write(bytes([label]))
                off=16+i*784
                f.write(pack16([lut[v] for v in im[off:off+784]]))
    print('Prepared',a.out)

if __name__=='__main__':
    main()
