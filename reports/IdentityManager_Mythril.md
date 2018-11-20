# Analysis results for tmp/IdentityManager.sol

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getDeployedMetaIds()`
- PC address: 1038

### Description

A possible integer overflow exists in the function `getDeployedMetaIds()`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/IdentityManager.sol:1544

### Code

```
function getDeployedMetaIds() public view returns(address[] addrs) {
        return metaIds;
    }
```

## Message call to external contract

- Type: Informational
- Contract: Unknown
- Function name: `createMetaId(address)`
- PC address: 1594

### Description

This contract executes a message call to to another contract. Make sure that the called contract is trusted and does not execute user-supplied code.
In file: tmp/IdentityManager.sol:1494

### Code

```
REG.getPermission(THIS_NAME, _addr)
```

## Transaction order dependence

- Type: Warning
- Contract: Unknown
- Function name: `createMetaId(address)`
- PC address: 1594

### Description

A possible transaction order independence vulnerability exists in function createMetaId(address). The value or direction of the call statement is determined from a tainted storage location
In file: tmp/IdentityManager.sol:1494

### Code

```
REG.getPermission(THIS_NAME, _addr)
```

## Exception state

- Type: Informational
- Contract: Unknown
- Function name: `_function_0x73fd4e8f`
- PC address: 1693

### Description

A reachable exception (opcode 0xfe) has been detected. This can be caused by type errors, division by zero, out-of-bounds array access, or assert violations. This is acceptable in most situations. Note however that `assert()` should only be used to check invariants. Use `require()` for regular input checking.
In file: tmp/IdentityManager.sol:1503

### Code

```
address[] public metaIds
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `addMetaId(address,address)`
- PC address: 1881

### Description

A possible integer overflow exists in the function `addMetaId(address,address)`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/IdentityManager.sol:1

### Code

```
;

contract ERC165
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getDeployedMetaIds()`
- PC address: 2435

### Description

A possible integer overflow exists in the function `getDeployedMetaIds()`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/IdentityManager.sol:1545

### Code

```
return metaIds
```

## Integer Overflow 

- Type: Warning
- Contract: Unknown
- Function name: `getDeployedMetaIds()`
- PC address: 2437

### Description

A possible integer overflow exists in the function `getDeployedMetaIds()`.
The addition or multiplication may result in a value higher than the maximum representable integer.
In file: tmp/IdentityManager.sol:1545

### Code

```
return metaIds
```

