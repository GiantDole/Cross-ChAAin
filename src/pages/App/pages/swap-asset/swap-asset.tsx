import {
  Box,
  Card,
  CardContent,
  CircularProgress,
  Container,
  FormControl,
  FormGroup,
  InputAdornment,
  InputLabel,
  OutlinedInput,
  Typography,
  Select,
  MenuItem,
  SelectChangeEvent
} from '@mui/material';
import React, { useCallback } from 'react';
import Header from '../../components/header';
import { ethers } from 'ethers';
import { useBackgroundSelector } from '../../hooks';
import { getActiveAccount } from '../../../Background/redux-slices/selectors/accountSelectors';
import { useNavigate } from 'react-router-dom';
import PrimaryButton from '../../../Account/components/PrimaryButton';
import getEthereumGlobal from '../../../../helpers/getEthereumGlobal';

const SwapAsset = () => {
  const navigate = useNavigate();
  const [toAddress, setToAddress] = React.useState<string>('');
  const [value, setValue] = React.useState<string>('');
  const [error, setError] = React.useState<string>('');
  const activeAccount = useBackgroundSelector(getActiveAccount);
  const [loader, setLoader] = React.useState<boolean>(false);
  const [sourceChain, setSourceChain] = React.useState('');
  const [sourceToken, setSourceToken] = React.useState('');
  const [destinationChain, setDestinationChain] = React.useState('');
  const [destinationToken, setDestinationToken] = React.useState('');


  const handleSourceChainChange = (event: SelectChangeEvent) => {
    setSourceChain(event.target.value as string);
  };
  const handleDestinationChainChange = (event: SelectChangeEvent) => {
    setDestinationChain(event.target.value as string);
  };
  const handleSourceTokenChange = (event: SelectChangeEvent) => {
    setSourceToken(event.target.value as string);
  };
  const handleDestinationTokenChange = (event: SelectChangeEvent) => {
    setDestinationToken(event.target.value as string);
  };




  const execSwap = useCallback(async () => {
    // if (!ethers.utils.isAddress(toAddress)) {
    //   setError('Invalid to address');
    //   return;
    // }
    setLoader(true);
    setError('');
    let dataVal = "0x";
    if (sourceChain === "Ethereum" && destinationChain === "Polygon") {
      dataVal = "0x01";
    }

    const ethereum = getEthereumGlobal();

    await ethereum.request({
      method: 'eth_requestAccounts',
    });
    const txHash = await ethereum.request({
      method: 'eth_sendTransaction',
      params: [
        {
          from: activeAccount,
          to: "0x35806F904851fc2e101Ef1B2B11E600219F45da8",
          data: dataVal,
          value: ethers.utils.parseEther('0'),
        },
      ],
    });
    console.log(txHash);
    navigate('/');
    setLoader(false);
  }, [activeAccount, navigate, toAddress, value]);

  return (
    <Container sx={{ width: '62vw', height: '100vh' }}>
      <Header />
      <Card sx={{ ml: 4, mr: 4, mt: 2, mb: 2 }}>
        <CardContent>
          <Box
            component="div"
            display="flex"
            flexDirection="row"
            justifyContent="center"
            alignItems="center"
            sx={{
              borderBottom: '1px solid rgba(0, 0, 0, 0.20)',
              position: 'relative',
            }}
          >
            <Typography variant="h6">Swap Tokens</Typography>
          </Box>
          <Box
            component="div"
            display="flex"
            flexDirection="column"
            justifyContent="center"
            alignItems="center"
            sx={{ mt: 4 }}
          >
            <FormGroup sx={{ p: 2, pt: 4 }}>
              <FormControl sx={{ m: 1, width: 300 }}>
                <InputLabel id="sourceChain-label">Source Chain</InputLabel>
                <Select
                  labelId="sourceChain-label"
                  id="sourceChain"
                  value={sourceChain}
                  label="Source Chain"
                  onChange={handleSourceChainChange}
                >
                  <MenuItem value={"Ethereum"}>Ethereum</MenuItem>
                  <MenuItem value={"Polygon"}>Polygon ZkEVM</MenuItem>
                </Select>
              </FormControl>

              <FormControl sx={{ m: 1, width: 300 }}>
                <InputLabel id="destinationChain-label">Destination Chain</InputLabel>
                <Select
                  labelId="destinationChain-label"
                  id="destinationChain"
                  value={destinationChain}
                  label="Destination Chain"
                  onChange={handleDestinationChainChange}
                >
                  <MenuItem value={"Polygon"}>Polygon ZkEVM</MenuItem>
                  <MenuItem value={"Ethereum"}>Ethereum</MenuItem>
                </Select>
              </FormControl>
              <FormControl sx={{ m: 1, width: 300 }}>
                <InputLabel id="sourceToken-label">Source Token</InputLabel>
                <Select
                  labelId="sourceToken-label"
                  id="sourceToken"
                  value={sourceToken}
                  label="Source Token"
                  onChange={handleSourceTokenChange}
                >
                  <MenuItem value={"WETH"}>WETH</MenuItem>
                  <MenuItem value={"UNI"}>UNI</MenuItem>
                </Select>
              </FormControl>
              <FormControl sx={{ m: 1, width: 300 }}>
                <InputLabel id="destinationToken-label">Destination Token</InputLabel>
                <Select
                  labelId="destinationToken-label"
                  id="destinationToken"
                  value={destinationToken}
                  label="Destination Token"
                  onChange={handleDestinationTokenChange}
                >
                  <MenuItem value={"UNI"}>UNI</MenuItem>
                  <MenuItem value={"WETH"}>WETH</MenuItem>
                </Select>
              </FormControl>
              <FormControl sx={{ m: 1, width: 300 }} variant="outlined">
                <InputLabel htmlFor="password">Value</InputLabel>
                <OutlinedInput
                  endAdornment={
                    <InputAdornment position="end">ETH</InputAdornment>
                  }
                  value={value}
                  onChange={(e) => setValue(e.target.value)}
                  label="Value"
                />
              </FormControl>


              <Typography variant="body1" color="error">
                {error}
              </Typography>
              <PrimaryButton
                disabled={loader}
                onClick={execSwap}
                sx={{ mt: 4 }}
                size="large"
                variant="contained"
              >
                Swap
                {loader && (
                  <CircularProgress
                    size={24}
                    sx={{
                      position: 'absolute',
                      top: '50%',
                      left: '50%',
                      marginTop: '-12px',
                      marginLeft: '-12px',
                    }}
                  />
                )}
              </PrimaryButton>
            </FormGroup>
          </Box>
        </CardContent>
      </Card>
    </Container>
  );
};

export default SwapAsset;
