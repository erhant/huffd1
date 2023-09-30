from sage.all import GF, FiniteField, PolynomialRing, Polynomial, is_prime
from typing import List


# proof of concept in Sage
class HUFFD1:
    F: FiniteField  # type: ignore
    Fx: PolynomialRing  # type: ignore
    total_supply: int
    order: int
    basises: List[Polynomial]
    balances: Polynomial

    def __init__(
        self, order: int, total_supply: int, coeff_size: int, owners: List[int]
    ) -> None:
        assert is_prime(order)
        self.order = order
        self.F = GF(order)
        self.Fx = self.F["x"]
        self.total_supply = total_supply
        self.coeff_size = coeff_size

        # basis
        self.basises = [self.__compute_basis(t) for t in range(self.total_supply)]

        # interpolation
        # NOTE: original idea was to interpolate for some owners, but if all tokens belong to owner
        # at the first step, we can simply assign owner as the constant polynomial
        # also, doing interpolation requires a lot more work in Huff, such as XGCD for divison and such.
        self.balances = self.__interpolate_basis(self.basises, owners)
        for t in range(self.total_supply):
            assert self.ownerOf(t) == owners[t]

    def __compute_basis(self, t):
        """
        Compute the Lagrange basis polynomial over field `F` for a given token id `t`
        where the total supply is `n`.
        """
        p: Polynomial = self.Fx([1])
        for i in range(self.total_supply):
            if i != t:
                p *= self.Fx([-i, 1])
                p /= self.F(t - i)
        return p

    def __interpolate_basis(self, bs, vals):
        """
        Given the basis vectors for `n` tokens, and values for each token,
        interpolate a polynomial.
        """
        assert len(bs) == len(vals)
        p = self.Fx([0])
        for i in range(len(bs)):
            p += bs[i] * self.F(vals[i])
        return p

    def __pad_coeff(self, val: int) -> str:
        """
        Remove 0x, and left-pad 0s.
        """
        return hex(val)[2:].rjust(self.coeff_size * 2, "0")

    def ownerOf(self, t: int):
        assert t < self.total_supply
        return self.balances(t)

    def balanceOf(self, addr: int):
        ans = 0
        for t in range(self.total_supply):
            ans += 1 if self.ownerOf(t) == addr else 0
        return ans

    def transferFrom(self, src: int, dest: int, t: int):
        assert t < self.total_supply
        assert self.ownerOf(t) == src

        # P'(x) = P(x) + L_t(x)(to - from)
        self.balances = self.balances + self.basises[t] * (dest - src)

    def print_owners(self):
        for t in range(self.total_supply):
            print(t, hex(self.ownerOf(t)))

    def print_coeffs(self):
        for coeff in self.balances.coefficients():
            print(hex(coeff))

    def print_basis_polys(self):
        for t in range(self.total_supply):
            print("t = ", t)
            # sparse=False so that 0s are returned too
            for c in self.basises[t].coefficients(sparse=False):
                print(self.__pad_coeff(c))

    def export_basis_table(self):
        body = "0x"
        for t in range(self.total_supply):
            # sparse=False so that 0s are returned too
            for c in self.basises[t].coefficients(sparse=False):
                body += self.__pad_coeff(c)

        code = "#define table Basis {\n    " + body + "\n}"
        code = code + "\n#define constant TOTAL_SUPPLY = " + hex(self.total_supply)
        code = code + "\n#define constant COEFF_SIZE = " + hex(self.coeff_size)
        code = code + "\n#define constant ORDER = " + hex(self.order)
        code = code + "\n"
        path = "./src/data/Basis" + str(self.total_supply) + ".huff"
        with open(path, "w") as _file:
            _file.write(code)
            print("exported basis table to: " + path)


# OWNER = 0xE175a857Fdefd7308D4B79936A5E31afa7bDD4aC # my address
# TOTAL_SUPPLY = 0xFF # number of tokens
# COEFF_SIZE = 0x14 # number of bytes
# ORDER = 0xffffffffffffffffffffffffffffffffffffffd1 # largest 160-bit prime

if __name__ == "__main__":
    TOTAL_SUPPLY = 3  # degree of polynomial + 1
    COEFF_SIZE = 1  # bytes
    ORDER = 13  # order of finite field for coefficients

    OWNER = 0x1
    assert OWNER < ORDER  # order must be larger than the owner (address)
    assert ORDER <= 2 ** (COEFF_SIZE * 8)  # order must fit into the coefficient size

    huffd1 = HUFFD1(
        ORDER, TOTAL_SUPPLY, COEFF_SIZE, [OWNER for _ in range(TOTAL_SUPPLY)]
    )

    for t in range(TOTAL_SUPPLY):
        assert huffd1.ownerOf(t) == OWNER

    huffd1.print_basis_polys()
    # print(huffd1.bs[0])

    # test transfer
    # TODO

    # export table for Huff
    huffd1.export_basis_table()
