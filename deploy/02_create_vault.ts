import { DeployFunction } from 'hardhat-deploy/types';

const YIELD_VAULT_FACTORY = 'YieldVaultFactory';

const func: DeployFunction = async function (hre) {
  const { deployments, getNamedAccounts } = hre;
  const { execute, get, log } = deployments;
  const { deployer } = await getNamedAccounts();

  if (!deployer) {
    throw Error(`The 'deployer' named account wasn't set`);
  }

  const factoryDeployment = await get(YIELD_VAULT_FACTORY);
  log(`Using YieldVaultFactory at: ${factoryDeployment.address}`);

  const receipt = await execute(
    YIELD_VAULT_FACTORY,
    { from: deployer },
    'createVault',
    'Test Yield Vault',
    'TYV',
    '0xAA40c0c7644e0b2B224509571e10ad20d9C4ef28',
    deployer
  );
  const event = receipt.events?.find((e) => e.event === 'UpgradableVaultCreated');
  if (event) {
    console.log('Vault is deployed at:', event.args[0]);
  }
};

func.tags = ['CreateVault'];
func.dependencies = ['YieldVaultFactory'];

export default func;
