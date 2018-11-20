# Analysis results for tmp/MetaIdentity.sol

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getKey(bytes32)`
- PC address: 1108

### Description

A possible integer overflow exists in the function `getKey(bytes32)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:267

### Code

```
function getKey(
        bytes32 _key
    )
        public
        view
        returns(uint256[] purposes, uint256 keyType, bytes32 key)
    {
        KeyStore.Key memory k = allKeys.keyData[_key];
        purposes = k.purposes;
        keyType = k.keyType;
        key = k.key;
    }
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `claimToSign(address,uint256,bytes)`
- PC address: 1344

### Description

A possible integer overflow exists in the function `claimToSign(address,uint256,bytes)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:694

### Code

```
function claimToSign(address subject, uint256 topic, bytes data)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(subject, topic, data));
    }
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getClaimIdsByType(uint256)`
- PC address: 1729

### Description

A possible integer overflow exists in the function `getClaimIdsByType(uint256)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:644

### Code

```
function getClaimIdsByType(uint256 _topic)
        public
        view
        returns(bytes32[] claimIds)
    {
        claimIds = claimsByTopic[_topic];
    }
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getSignatureAddress(bytes32,bytes)`
- PC address: 1959

### Description

A possible integer overflow exists in the function `getSignatureAddress(bytes32,bytes)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:706

### Code

```
function getSignatureAddress(bytes32 toSign, bytes signature)
        public
        pure
        returns (address)
    {
        return keccak256(abi.encodePacked(ETH_PREFIX, toSign)).recover(signature);
    }
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getKey(bytes32)`
- PC address: 6987

### Description

A possible integer overflow exists in the function `getKey(bytes32)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:274

### Code

```
KeyStore.Key memory k = allKeys.keyData[_key]
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getKey(bytes32)`
- PC address: 6989

### Description

A possible integer overflow exists in the function `getKey(bytes32)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:274

### Code

```
KeyStore.Key memory k = allKeys.keyData[_key]
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getClaimIdsByType(uint256)`
- PC address: 7882

### Description

A possible integer overflow exists in the function `getClaimIdsByType(uint256)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:649

### Code

```
claimIds = claimsByTopic[_topic]
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getClaimIdsByType(uint256)`
- PC address: 7884

### Description

A possible integer overflow exists in the function `getClaimIdsByType(uint256)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:649

### Code

```
claimIds = claimsByTopic[_topic]
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `addKey(bytes32,uint256,uint256)`
- PC address: 18839

### Description

A possible integer overflow exists in the function `addKey(bytes32,uint256,uint256)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:340

### Code

```
Key memory k = self.keyData[key]
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `addKey(bytes32,uint256,uint256)`
- PC address: 18841

### Description

A possible integer overflow exists in the function `addKey(bytes32,uint256,uint256)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/MetaIdentity.sol:340

### Code

```
Key memory k = self.keyData[key]
```

