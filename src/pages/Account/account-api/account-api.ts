import { ethers, Wallet } from 'ethers';
import { UserOperationStruct } from '@account-abstraction/contracts';

import { AccountApiParamsType, AccountApiType } from './types';
import { MessageSigningRequest } from '../../Background/redux-slices/signing';
import { TransactionDetailsForUserOp } from '@account-abstraction/sdk/dist/src/TransactionDetailsForUserOp';
import config from '../../../exconfig';
import { SimpleAccountAPI } from '@account-abstraction/sdk';
import { useDebugValue } from 'react';

const FACTORY_ADDRESS = config.factory_address;

/**
 * An implementation of the BaseAccountAPI using the SimpleAccount contract.
 * - contract deployer gets "entrypoint", "owner" addresses and "index" nonce
 * - owner signs requests using normal "Ethereum Signed Message" (ether's signer.signMessage())
 * - nonce method is "nonce()"
 * - execute method is "execFromEntryPoint()"
 */
class SimpleAccountTrampolineAPI
  extends SimpleAccountAPI
  implements AccountApiType {
  /**
   *
   * We create a new private key or use the one provided in the
   * deserializeState and initialize the SimpleAccountAPI
   */
  constructor(params: AccountApiParamsType<{}, { privateKey: string }>) {
    super({
      ...params,
      index: 0,
      owner: params.deserializeState?.privateKey
        ? new ethers.Wallet(params.deserializeState?.privateKey)
        : ethers.Wallet.createRandom(),
      factoryAddress: FACTORY_ADDRESS,
    });
  }

  /**
   *
   * @returns the serialized state of the account that is saved in
   * the secured vault in localstorage and later passed to the
   * constructor in the deserializeState parameter
   */
  serialize = async (): Promise<{ privateKey: string }> => {
    return {
      privateKey: (this.owner as Wallet).privateKey,
    };
  };

  /**
   * Called when the Dapp requests eth_signTypedData
   */
  signMessage = async (
    context: any,
    request?: MessageSigningRequest
  ): Promise<string> => {
    throw new Error('signMessage method not implemented.');
  };

  /**
   * Called after the user is presented with the pre-transaction confirmation screen
   * The context passed to this method is the same as the one passed to the
   * onComplete method of the PreTransactionConfirmationComponent
   */
  async createUnsignedUserOpWithContext(
    info: TransactionDetailsForUserOp,
    preTransactionConfirmationContext?: any
  ): Promise<UserOperationStruct> {
    console.log("createUnsignedUserOpWithContext: ", info)
    const userOp = await this.createUnsignedUserOp(info);
    console.log("userOp initial: ", userOp)

    const preVerificationGas = ethers.BigNumber.from(await userOp.preVerificationGas);
    const verificationGasLimit = ethers.BigNumber.from(userOp.verificationGasLimit);
    const callGasLimit = ethers.BigNumber.from(userOp.callGasLimit);

    // Apply the formula
    const prefund_native = preVerificationGas
      .add(verificationGasLimit.mul(3))
      .add(callGasLimit);

    const prefund_native_hex = prefund_native.toHexString();


    // Define the function signature in the ABI
    const contractAbi = ["function test(address,uint256)"];

    // Initialize a new Interface with the ABI
    const iface = new ethers.utils.Interface(contractAbi);

    // Define the function parameters
    const params = ["0xb16F35c0Ae2912430DAc15764477E179D9B9EbEa", prefund_native_hex];

    // Use the `encodeFunctionData` method to create the calldata
    const calldata = iface.encodeFunctionData("test", params);

    console.log("calldata", calldata);  // Outputs the calldata for the function
    userOp.callData = calldata;
    console.log("userOp final: ", userOp)
    return {
      ...(userOp),
      paymasterAndData: preTransactionConfirmationContext?.paymasterAndData
        ? preTransactionConfirmationContext?.paymasterAndData
        : '0x',
    };
  }

  async createSignedUserOp(info: TransactionDetailsForUserOp): Promise<UserOperationStruct> {
    const userOp = await super.createUnsignedUserOp(info);
    const userOpCallData = await userOp.callData;
    console.log("userOpCallData: ", userOpCallData);
    return userOp
  }

  /**
   * Callled after the user has accepted the transaction on the transaction confirmation screen
   * The context passed to this method is the same as the one passed to the
   * onComplete method of the TransactionConfirmationComponent
   */
  signUserOpWithContext = async (
    userOp: UserOperationStruct,
    postTransactionConfirmationContext: any
  ): Promise<UserOperationStruct> => {
    console.log("signUserOpWithContext: ", userOp)
    return this.signUserOp(userOp);
  };
}

export default SimpleAccountTrampolineAPI;
