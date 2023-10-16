<p align="center">
  <h1 align="center">
    <code>huffd1</code>
  </h1>
  <p align="center">
    <i>An NFT with Huff, using polynomials over a finite field of order the largest prime address, instead of mappings.</i>
  </p>
</p>

<p align="center">
    <a href="https://opensource.org/licenses/MIT" target="_blank">
        <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-yellow.svg">
    </a>
    <a href="./.github/workflows/tests.yml" target="_blank">
        <img alt="Workflow: Tests" src="https://github.com/erhant/huffd1/actions/workflows/tests.yaml/badge.svg?branch=main">
    </a>
</p>

## Methodology

`huffd1` is a non-fungible token implementation in Huff, where instead of ownership and approval mappings, we use polynomials $P[X]$ defined over the finite field of prime order $p = 2^{160} - 47$ that is the largest 160-bit prime:

$$
p = \mathtt{0xff}\ldots\mathtt{ffd1}
$$

Notice the final hexadecimals, which is where the name of the project comes from. The degree of the polynomial is equal to total supply minus one, so for $n$ tokens we have a polynomial $P$:

$$
P \in \mathbb{F}_{\mathtt{0xff}\ldots\mathtt{ffd1}}^{n-1}[X]
$$

Denote that ownership polynomial and approvals polynomial as $B[X]$ and $A[X]$ respectively. At contract deployment, all tokens are owned by the contract owner; and as a result the main polynomial is simply a constant polynomial equal to the owner address $B[X] = \mathtt{owner}$. There are also no approvals at first, so it is also a constant polynomial $A[X] = 0$.

### Updating a Polynomial

In a mapping `A` we could access the value stored at `t` as `A[t]`. Now, with a polynomial $A$, we evaluate $A(t)$ to find the "stored" value. The trick is on how one would update a polynomial the same way one could update a mapping.

We treat the polynomial as an interpolation over many Lagrange basis polynomials $L_0, L_1, \ldots, L_{T-1}$ over $T$ points (total supply), where $L_t[X]$ is defined as a polynomial that is equal to 1 at $t$ and 0 on all other points.

To update $A(t)$ to any value, we can surgically remove the current evaluation, and replace it with our own using the Lagrange basis for that point $t$. For example, to replace $A(t) = n$ with $A(t) = m$ we do:

$$
A[X] := A[X] + L_t[X](m - n)
$$

Note that since we are operating over a finite-field, multiplications will use `MULMOD` and additions will use `ADDMOD`. Also note that $-a$ is obtained by $p-a$ where $p$ is the order of the finite field.

### Storing the Basis Polynomials

The basis polynomials are computed before deploying the contract, and are stored within the contract bytecode. We have a [Sage script](./src/Huffd1.sage) that can export the basis polynomials, one for each token id, as a codetable where the coefficients of each polynomial are concatenated.

```c
// basis polynomials coefficients
#define table Basis {
  // 0x...
}

// number of tokens
#define constant TOTAL_SUPPLY = 0xa // 10 tokens

// number of bytes per coefficient
#define constant COEFF_SIZE = 0x14 // 20 bytes

// order of the finite field
#define constant ORDER = 0xffffffffffffffffffffffffffffffffffffffd1
```

Using these, we can load polynomials from the code table.

> <picture>
>   <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/Mqxx/GitHub-Markdown/main/blockquotes/badge/light-theme/warning.svg">
>   <img alt="Warning" src="https://raw.githubusercontent.com/Mqxx/GitHub-Markdown/main/blockquotes/badge/dark-theme/warning.svg">
> </picture><br>
>
> The codetable grows pretty large for 20-byte coefficient size, and may easily get past the 24KB maximum contract size. To be more specific, for coefficient size `S` and total supply `N`, you will have `N` polynomials with `N` coefficients each, with `S` bytes per coefficient, resulting in total number of bytes of `N * N * S`.

### Evaluating the Polynomial

We use [Horner's method](https://zcash.github.io/halo2/background/polynomials.html#aside-horners-rule) to efficiently evaluate our polynomial. With this method, instead of:

$$
a_0 + a_1X + a_2X^2 + \ldots a_{T-1}X^{T-1}
$$

we do:

$$
a_0 + X(a_1 + X(a_2 + \ldots + X(a_{T-2} + X(a_{T-1})))
$$

which also plays nicely with the reverse coefficient form that we use to store the polynomials.

## Usage

[`huffd1`](./src/Huffd1.huff) implements the following methods:

- `name`: returns the string `"Huffd1"`.
- `symbol`: returns the string `"FFD1"`.
- `ownerOf`: evaluates $B[X]$ at the given token id `t`.
- `balanceOf`: evaluates $B[X]$ over all token ids, counting the matching addresses along the way (beware of gas).
- `transfer`: updates $B[X]$ with the new address.
- `transferFrom`: updates $B[X]$ with the new address.
- `approve`: updates $A[X]$ with the new address.
- `getApproved`: evaluates $A[X]$ at the given token id `t`.

It also includes ownership stuff in [`Owned.huff`](./src/util/Owned.huff) imported from [Huffmate](https://github.com/huff-language/huffmate/blob/main/src/auth/Owned.huff). Polynomial operations are implemented under [`Polynomial.huff`](./src/util/Polynomial.huff).

## Testing

You can use the following commands for testing.

```sh
# run all tests
forge t -vvv

# run a specific test
forge t -vvv --mc Polynomial
forge t -vvv --mc Huffd1
```

I use `-vvv` to see reverts in detail.

> <picture>
>   <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/Mqxx/GitHub-Markdown/main/blockquotes/badge/light-theme/note.svg">
>   <img alt="Warning" src="https://raw.githubusercontent.com/Mqxx/GitHub-Markdown/main/blockquotes/badge/dark-theme/note.svg">
> </picture><br>
>
> The stack comments are written in reverse order:
>
> ```c
> opcode // [top-N, ..., top-1, top]
> pop    // [top-N, ..., top-1]
> 0x01   // [top-N, ..., top-1, 0x01]
> ```
>
> unlike the usual order described in the [Style Guide](https://docs.huff.sh/style-guide/overview/).

## Remarks

- This project was done for the [Huff hackathon](https://huff.sh/hackathon)!

- We could also use $p = 2^{160} + 7$, but I wanted all coefficients to be strictly 160-bits, which is not the case with that prime. In fact, the concept works for any prime order, but we would like to use an order that can fit almost all the addresses while being as large as an address.

- Maybe use foundry FFI to generate the basis polynomials during contract creation?
