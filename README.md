# `huffd1`

`huffd1` is a non-fungible token implementation in Huff, where the ownership of a token is given by the evaluation of a polynomial $P(x)$, defined over the finite field of prime order $p = 2^{160} - 47$, equal to `0xffffffffffffffffffffffffffffffffffffffd1` (hence the name), the largest 160-bit prime. Note that we could also use $p = 2^{160} + 7$, but I wanted all coefficients to be strictly 160-bits, which is not the case with that prime.

The concept works for any order actually, but we would like to use an order that can fit almost all the addresses.

## TODO

- have polynomial for approvals too?
- maybe use FFI to generate the basis based on total supply via script?
- bug with memory offsets somehow?

## Usage

Let's describe each function:

### `ownerOf`

To find the owner of a token $t$, simply evaluate $P(t)$ and the result will be a 160-bit number corresponding to the owner address. We use Horner's method to efficiently evaluate our polynomial.

Initially, all tokens are owned by the contract deployer, which can be represented by the constant polynomial that is equal to the owner address.

### `balanceOf`

To find the balance of an address, iterate over all tokens and call `ownerOf`, counting the number of matching addresses along the way.

### `transfer`

To transfer a token $t$ from address $a \to b$, update $P(x)$ to be $P(x) + L_t(x)(b - a)$. Here, $L_t(x)$ is the Lagrange basis of the token, defined as a polynomial that is equal to 1 at $t$ and 0 on all other points.

This operation results in multiplying the coefficients of $L_t(x)$ with $(b - a)$ which we will do via `MULMOD`, and afterwards summation of the coefficients of $P(x)$ and the resulting polynomial from previous step, using `ADDMOD`.

Also note that $-a$ is obtained by $p-a$ where $p$ is the order of the finite field.
