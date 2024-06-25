import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const MetaDogModule = buildModule('MetaDogModule', (m) => {
  const placeholder = m.getParameter('placeholder', 'ipfs://');
  const proxyAddress = m.getParameter(
    'proxyaddress',
    '0xa5409ec958C83C3f309868babACA7c86DCB077c1'
  );

  const metadog = m.contract('MetaDog', [
    'metadog',
    'md',
    placeholder,
    proxyAddress,
    m.getAccount(0),
  ]);

  return { metadog };
});

const MetaDogReserve = buildModule('MetaDogReserve', (m) => {
  const metadogAddress = m.getParameter('address');
  const metadog = m.contractAt('MetaDog', metadogAddress);
  m.call(metadog, 'collectReserves');

  return { metadog };
});

const MetaDogPresale = buildModule('MetaDogPresale', (m) => {
  const metadogAddress = m.getParameter('address');
  const whitelistRoot = m.getParameter('whitelistRoot');
  const metadog = m.contractAt('MetaDog', metadogAddress);
  m.call(metadog, 'setWhitelistMerkleRoot', [whitelistRoot]);
  return { metadog };
});

const MetaDogPublicSale = buildModule('MetaDogPublicSale', (m) => {
  const metadogAddress = m.getParameter('address');
  const metadog = m.contractAt('MetaDog', metadogAddress);
  m.call(metadog, 'startPublicSale');

  return { metadog };
});

const MetaDogReveal = buildModule('MetaDogReveal', (m) => {
  const metadogAddress = m.getParameter('address');
  const revealTokenURI = m.getParameter('revealTokenURI');
  const metadog = m.contractAt('MetaDog', metadogAddress);

  m.call(metadog, 'setBaseURI', [`ipfs://${revealTokenURI}/`]);
  return { metadog };
});

export default MetaDogModule;
export { MetaDogReserve, MetaDogPresale, MetaDogPublicSale, MetaDogReveal };
