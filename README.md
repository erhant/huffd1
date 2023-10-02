# `huffd1`

`huffd1` is a non-fungible token implementation in Huff, where the ownership of a token is given by the evaluation of a polynomial $P(x)$, defined over the finite field of prime order $p = 2^{160} - 47$, the largest 160-bit prime:

$$
p = \mathtt{0xffffffffffffffffffffffffffffffffffffffd1}
$$

Notice the final hexadecimals, which is where the name of the project comes from. The degree of the polynomial is equal to total supply - 1, so for $n$ tokens we have a polynomial $P$:

$$
P \in \mathbb{F}_\mathtt{0xffffffffffffffffffffffffffffffffffffffd1}^{n-1}[X]
$$

> <picture>
>   <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/Mqxx/GitHub-Markdown/main/blockquotes/badge/light-theme/warning.svg">
>   <img alt="Warning" src="https://raw.githubusercontent.com/Mqxx/GitHub-Markdown/main/blockquotes/badge/dark-theme/warning.svg">
> </picture><br>
>
> The stack comments are written in reverse order:
>
> ```c
> opcode // [top-N, ..., top-1, top]
> pop    // [top-N, ..., top-1]
> 0x01   // [top-N, ..., top-1, 0x01]
> ```

## Usage

We have a Sage script that can export the basis polynomials, one for each token id, as a codetable where the coefficients of each polynomial are concatenated.

```c
// basis polynomials coefficients
#define table Basis {
  // 0x...
}

// number of tokens
#define constant TOTAL_SUPPLY = 0xa

// number of bytes per coefficient
#define constant COEFF_SIZE = 0x14

// order of the finite field
#define constant ORDER = 0xffffffffffffffffffffffffffffffffffffffd1
```

Using these, we can load polynomials from the code table, and work with them using [`Polynomial.huff`](./src/util/Polynomial.huff). Note that this codetable grows pretty large for 20-byte coefficient size, and may easily get past the 24KB maximum contract size.

Let's describe each function of [`huffd1`](./src/Huffd1.huff):

### `ownerOf`

To find the owner of a token $t$, simply evaluate $P(t)$ and the result will be a 160-bit number corresponding to the owner address. We use [Horner's method](https://zcash.github.io/halo2/background/polynomials.html#aside-horners-rule) to efficiently evaluate our polynomial.

Initially, all tokens are owned by the contract deployer, which can be represented by the constant polynomial that is equal to the owner address.

### `balanceOf`

To find the balance of an address, iterate over all tokens and call `ownerOf`, counting the number of matching addresses along the way.

### `transfer`

To transfer a token $t$ from address $a \to b$, update $P(x)$ to be $P(x) + L_t(x)(b - a)$. Here, $L_t(x)$ is the Lagrange basis of the token, defined as a polynomial that is equal to 1 at $t$ and 0 on all other points.

This operation results in multiplying the coefficients of $L_t(x)$ with $(b - a)$ which we will do via `MULMOD`, and afterwards summation of the coefficients of $P(x)$ and the resulting polynomial from previous step, using `ADDMOD`.

Also note that $-a$ is obtained by $p-a$ where $p$ is the order of the finite field.

#### `name`

Returns the string `"Huffd1"`.

### `symbol`

Returns the string `"FFD1"`.

## Testing

Simply do:

```sh
forge test
```

It shall test both the polynomial utilities and the `huffd1` contract.

## Further Works

- We can implement approvals with another polynomial too, but time did not permit. Also, there are many optimizations to do in many different places within the code.

- We could also use $p = 2^{160} + 7$, but I wanted all coefficients to be strictly 160-bits, which is not the case with that prime. In fact, the concept works for any prime order, but we would like to use an order that can fit almost all the addresses while being as large as an address.

- Maybe use foundry FFI to generate the basis polynomials during contract creation?
