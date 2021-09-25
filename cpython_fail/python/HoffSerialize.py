
import pandas as pd
import numpy as np
import cbor2

def toHoffCbor(df):
    return cbor2.dumps([list(df), [seriesToHoffCbor(df[s]) for s in df]])

def seriesToHoffCbor(s):
    (colType, func) = typeMap[s.dtype]
    # print(f'found "{colType}"')
    values =  list(s if func is None else func(s))
    # print(type(values[0]))
    return [colType,values]

def assertAllString(x):
    assert x.map(lambda y: type(y)==str).all(), f"the following column cannot be serialized to Hoff:\n{x}"
    return x


typeMap = {np.dtype('int64'):      ('IntCol'            , None),
           np.dtype('bool'):       ('BoolCol'           , None),
           np.dtype('O'):          ('TextCol'           , assertAllString),
           np.dtype('float64'):    ('DoubleCol'         , None),
           np.dtype('<M8[ns]'):    ('TimestampCol'      , lambda x: x.astype(int)),
           # pd.Int64Dtype():        ('IntCol'            , lambda x: list(x.values))
           }

def example():
    a = pd.DataFrame({'IntCol': [1,10], 'BoolCol':[True,False], 'TextCol':['sd','yi'], 'DoubleCol':[1.3, None],
                      # 'd': pd.Series([1,None], dtype='Int64')
                      })
    a['TimestampCol'] = pd.to_datetime(a.IntCol)
    print(a.dtypes)
    print({a[c].dtype:c for c in a})
    print(toHoffCbor(a).hex())
    return a

a=example()
