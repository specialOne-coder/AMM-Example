
module.exports = async function (taskArgs, hre) {

    const CasNFT = await ethers.getContract("CasNFT")
    console.log(`[source] Contract.address: ${CasNFT.address}`)

    const address = [
        "0x8a9c67fee641579deba04928c4bc45f66e26343a",
        "0x8a9c67fee641579deba04928c4bc45f66e26343a",
        "0x8a9c67fee641579deba04928c4bc45f66e26343a"
    ]
    try {
        let tx = await (await CasNFT.airdrop(address)).wait()
        console.log(`✅ [${hre.network.name}] airdrop is ok`)
        console.log(` tx: ${tx.transactionHash}`)
    } catch (e) {
        console.log("Erreur => ", e);
    }
}