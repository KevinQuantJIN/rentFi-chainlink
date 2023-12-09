// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

contract RentalCashFlowNFT is ERC721 {
    using PRBMathUD60x18 for uint256;
    mapping(uint256 => address) public tokenToRentalAgreement;
    AggregatorV3Interface internal dataFeed;

    struct RentalAgreementDetails {
        address landlord;
        address tenant;
        address rentalAgreementAddress;
        uint256 rent;
        uint256 deposit;
        uint256 rentGuarantee;
        string leaseTerm;
        string houseName;
        string houseAddress;
        address tokenAddress;
        uint256 initialPrice;
    }

    mapping(uint256 => RentalAgreementDetails) public rentalAgreements;

    constructor() ERC721("RentalCashFlowNFT", "RCF") {
        dataFeed = AggregatorV3Interface(
            0x7422A64372f95F172962e2C0f371E0D9531DF276
        );
    }

    function safeMint(
        address landlord,
        address tenant,
        address rentalAgreementAddress,
        uint256 rent,
        uint256 deposit,
        uint256 rentGuarantee,
        string memory leaseTerm,
        string memory houseName,
        string memory houseAddress,
        address tokenAddress
    ) public {
        uint256 tokenId = uint256(uint160(rentalAgreementAddress));
        _safeMint(landlord, tokenId);
        tokenToRentalAgreement[tokenId] = rentalAgreementAddress;
        rentalAgreements[tokenId] = RentalAgreementDetails({
            landlord: landlord,
            tenant: tenant,
            rentalAgreementAddress: rentalAgreementAddress,
            rent: rent,
            deposit: deposit,
            rentGuarantee: rentGuarantee,
            leaseTerm: leaseTerm,
            houseName: houseName,
            houseAddress: houseAddress,
            tokenAddress: tokenAddress,
            initialPrice: calculateInitialPrice(rent)
        });
    }

    function calculateInitialPrice(uint256 Rent) public view returns (uint256) {
        uint256 annualRiskFreeInterestRate = getInterestRate();
        // This function calculates the 12month DCF value of the rent using smart contract
        uint256 presentValue = Rent.mul(
            (1e18 - ((1e18 + annualRiskFreeInterestRate).inv().powu(12e18)))
                .div(annualRiskFreeInterestRate)
        );
        return presentValue;
    }

    function getInterestRate() public view returns (uint256) {
        int256 ETH_APR_90d;
        (
            ,
            /* uint80 roundID */ ETH_APR_90d,
            /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            ,
            ,

        ) = dataFeed.latestRoundData();
        uint256 annualRiskFreeInterestRate = uint256(ETH_APR_90d) * (1e11);
        return annualRiskFreeInterestRate;
    }
}
