# CIDv1.eth - On-Chain CIDv1 Encoder

A Solidity library for on-chain CIDv1 encoding, primarily using raw format for efficient on-chain content addressing. This library provides comprehensive multiformat utilities for encoding various data formats into Content Identifiers (CIDs) that can be used in smart contracts for IPFS/IPLD content referencing.

## 🎯 Project Status

- ✅ **122/122 tests passing**
- ✅ **100% coverage for all core multiformat libraries**
- ✅ **DAG-PB (final boss) defeated with 100% coverage**
- ✅ **All multihash implementations tested**
- ✅ **Comprehensive edge case testing**

## Components

### Multicodec
- **DAG-CBOR** : `dag-cbor.sol`
- **DAG-JSON** : `dag-json.sol` ⚠️ **String-based, inefficient - prefer JSON-UTF8**
- **DAG-PB** : `dag-pb.sol` ✅ **100% coverage (FINAL BOSS DEFEATED!)**
- **JSON UTF-8** : `json-utf8.sol` ✅ **Recommended for JSON encoding**
- **RAW binary** : `raw-bin.sol`
- **UnixFS** : `unix-fs.sol`

### Multihash
- **Keccak-256** : `keccak-256.sol`
- **SHA-256** : `sha-256.sol`
- **Identity/raw** : `identity-raw.sol`

### Utils Libraries
- **`Utils.sol`**: Core utility functions for encoding and decoding
- **`Varint.sol`**: Variable-length integer encoding/decoding

## Usage Examples

### RAW Binary Encoding
```solidity
import {RAW} from "./src/multiformats/multicodec/raw-bin.sol";

// Encode raw data with identity hash
bytes memory data = "Hello World";
bytes memory rawFile = RAW.raw(data);
// returns 0x0155000b48656c6c6f20576f726c64

// Encode raw data with SHA-256 hash
bytes memory rawFileSha256 = RAW.rawSha256(data);
// returns 0x01551220a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e

// Encode raw data with Keccak-256 hash
bytes memory rawFileKeccak256 = RAW.rawKeccak256(data);
// returns 0x01551b20592fa743889fc7f92ac2a37bb1f5ba1daf2a5c84741ca0e0061d243a2e6707ba
```

### JSON UTF-8 Encoding (Recommended)
```solidity
import {JSON_UTF8} from "./src/multiformats/multicodec/json-utf8.sol";

// Encode JSON data with identity hash (recommended)
bytes memory jsonData = bytes('{"Hello":"World"}');
bytes memory jsonRAW = JSON_UTF8.encode(jsonData);
// returns 0x01800400117b2248656c6c6f223a22576f726c64227d

// Encode JSON data with SHA-256 hash
bytes memory jsonSha256 = JSON_UTF8.encodeSha256(jsonData);
// returns 0x018004122065a4c4ca5acfc4bf3b34e138c808730f6c9ce141a4c6b889a9345e66c9739d73

// Encode JSON data with Keccak-256 hash
bytes memory jsonKeccak256 = JSON_UTF8.encodeKeccak256(jsonData);
// returns 0x0180041b20068cd05557eb0a2358c3fab33bcecc929f0b4f01caed8562f772bbeb8869eec9
```

### DAG-JSON Encoding (⚠️ Inefficient - Use JSON-UTF8 Instead)
```solidity
import {DAG_JSON} from "./src/multiformats/multicodec/dag-json.sol";

// ⚠️  WARNING: DAG-JSON is string-based and inefficient
// For most use cases, prefer JSON_UTF8.encode() which provides binary encoding
// and is more gas-efficient. DAG-JSON should only be used when you specifically
// need the DAG-JSON format for IPLD compatibility.

// Encode JSON data in DAG-JSON format (inefficient)
bytes memory jsonData = bytes('{"Hello":"World"}');
bytes memory dagJson = DAG_JSON.encode(jsonData);
// returns 0x01a90200117b2248656c6c6f223a22576f726c64227d

// Create DAG-JSON link (inefficient)
string memory key = "file";
bytes memory cidv1 = hex"0170000a48656c6c6f20576f726c64";
bytes memory link = DAG_JSON.link(key, cidv1);
// returns {"file":{"/":"f0170000a48656c6c6f20576f726c64"}}
```

### DAG-CBOR Directory
```solidity
import {DAG_CBOR} from "./src/multiformats/multicodec/dag-cbor.sol";
import {RAW} from "./src/multiformats/multicodec/raw-bin.sol";
import {JSON_UTF8} from "./src/multiformats/multicodec/json-utf8.sol";

// Create multiple raw files/hash
bytes memory helloWorld = "Hello World";
bytes memory rawFile = RAW.raw(helloWorld);
bytes memory rawFileSha256 = RAW.rawSha256(helloWorld);
bytes memory rawFileKeccak256 = RAW.rawKeccak256(helloWorld);

// Create directory entries
DAG_CBOR.KV[] memory rawDirData = new DAG_CBOR.KV[](4);
rawDirData[0] = DAG_CBOR.KV("raw.txt", rawFile);
rawDirData[1] = DAG_CBOR.KV("sha256.txt", rawFileSha256);
rawDirData[2] = DAG_CBOR.KV("keccak256.txt", rawFileKeccak256);
rawDirData[3] = DAG_CBOR.KV("hello.json", JSON_UTF8.encode('{"Hello":"World"}'));

// Encode directory
bytes memory rawDirMap = DAG_CBOR.map(rawDirData);
bytes memory cidv1Dir = DAG_CBOR.encode(rawDirMap);

// returns 0x0171008c01a36a7368613235362e747874d82a58250001551220a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e...
```

### DAG-PB Directory Encoding
```solidity
import {DAG_PB} from "./src/multiformats/multicodec/dag-pb.sol";
import {RAW} from "./src/multiformats/multicodec/raw-bin.sol";

// Create a file node
string memory helloWorld = "Hello IPFS";
bytes memory rawFile = RAW.raw(bytes(helloWorld));

// Create link and directory
bytes memory link = DAG_PB.link(rawFile, "hello.txt", bytes(helloWorld).length);
bytes[] memory links = new bytes[](1);
links[0] = link;
bytes memory encodedDir = DAG_PB.directory(links);
bytes memory dirCID = abi.encodePacked(
    bytes1(0x01), // CIDv1
    bytes1(0x70), // dag-pb codec
    bytes1(0x00), // identity multihash
    encodedDir.length.varint(),
    encodedDir
);
// returns 0x01700023121d0a0e0155000a48656c6c6f2049504653120968656c6c6f2e747874180a0a020801
```

## Format Recommendations

### ✅ Recommended Formats
- **JSON-UTF8**: Binary JSON encoding, gas-efficient, recommended for most JSON use cases
- **DAG-CBOR**: Binary CBOR encoding, efficient for complex data structures
- **RAW**: Simple binary data encoding
- **DAG-PB**: Protocol Buffer encoding for IPFS compatibility

### ⚠️ Use with Caution
- **DAG-JSON**: String-based, inefficient, only use when specifically required for IPLD compatibility

## Development

### Build
```shell
$ forge build
```

### Test
```shell
$ forge test
```

### Coverage
```shell
$ forge coverage
```

### Format
```shell
$ forge fmt
```

## Test Coverage

All core multiformat libraries have achieved **100% test coverage**:

| File                                        | % Lines          | % Statements     | % Branches     | % Funcs         |
|---------------------------------------------|------------------|------------------|----------------|-----------------|
| src/cidv1.sol                               | 0.00% (0/9)      | 0.00% (0/11)     | 0.00% (0/4)    | 0.00% (0/2)     |
| src/multiformats/multicodec/dag-cbor.sol    | 100.00% (41/41)  | 100.00% (50/50)  | 100.00% (6/6)  | 100.00% (8/8)   |
| src/multiformats/multicodec/dag-json.sol    | 100.00% (27/27)  | 100.00% (27/27)  | 100.00% (3/3)  | 100.00% (5/5)   |
| src/multiformats/multicodec/dag-pb.sol      | 100.00% (28/28)  | 100.00% (31/31)  | 100.00% (1/1)  | 100.00% (10/10) |
| src/multiformats/multicodec/json-utf8.sol   | 100.00% (12/12)  | 100.00% (9/9)    | 100.00% (0/0)  | 100.00% (6/6)   |
| src/multiformats/multicodec/raw-bin.sol     | 100.00% (6/6)    | 100.00% (3/3)    | 100.00% (0/0)  | 100.00% (3/3)   |
| src/multiformats/multicodec/unix-fs.sol     | 100.00% (34/34)  | 100.00% (46/46)  | 100.00% (4/4)  | 100.00% (6/6)   |
| src/multiformats/multihash/identity-raw.sol | 100.00% (2/2)    | 100.00% (1/1)    | 100.00% (0/0)  | 100.00% (1/1)   |
| src/multiformats/multihash/keccak-256.sol   | 100.00% (4/4)    | 100.00% (4/4)    | 100.00% (0/0)  | 100.00% (2/2)   |
| src/multiformats/multihash/sha-256.sol      | 100.00% (4/4)    | 100.00% (4/4)    | 100.00% (0/0)  | 100.00% (2/2)   |
| src/multiformats/varint.sol                 | 100.00% (10/10)  | 100.00% (13/13)  | 100.00% (4/4)  | 100.00% (1/1)   |
| **Total**                                   | **94.82% (183/193)** | **94.39% (202/214)** | **82.61% (19/23)** | **95.92% (47/49)** |

**Key Highlights:**
- ✅ **All core multiformat libraries**: 100% coverage across all metrics
- ✅ **DAG-PB (final boss)**: 100% coverage (28/28 lines, 31/31 statements, 1/1 branches, 10/10 functions)
- ✅ **122/122 tests passing** with comprehensive edge case coverage
- ⚠️ **cidv1.sol**: 0% coverage (example file, not core library)
- ⚠️ **Test files**: Included in coverage but not part of source code

## License
WTFPL.ETH
