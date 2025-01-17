import React, { useState } from "react";
import { Amount } from "~~/components/diceComponents/Amount";
import { Address as AddressType } from "@starknet-react/chains";
import { Address } from "~~/components/scaffold-stark";
import { formatEther } from "ethers";

export type Winner = {
  address: AddressType;
  amount: bigint | number;
};

export type WinnerEventsProps = {
  winners: Winner[];
};

export const WinnerEvents = ({ winners }: WinnerEventsProps) => {
  const [showUsdPrice, setShowUsdPrice] = useState(true);
  return (
    <div className="mx-10">
      <div className="flex w-auto justify-center h-10">
        <p className="flex justify-center text-lg font-bold ">Winner Events</p>
      </div>

      <table className="mt-4 p-2 bg-base-100 table table-zebra shadow-lg w-full overflow-hidden">
        <thead className="text-lg text-white">
          <tr>
            <th className="bg-secondary" colSpan={3}>
              Address
            </th>
            <th
              className="bg-secondary"
              colSpan={2}
              onClick={() => {
                setShowUsdPrice(!showUsdPrice);
              }}
            >
              Won
            </th>
          </tr>
        </thead>
        <tbody>
          {winners.map(({ address, amount }, i) => {
            return (
              <tr key={i}>
                <td colSpan={3}>
                  <Address address={address} size="lg" />
                </td>
                <td
                  colSpan={2}
                  onClick={() => {
                    setShowUsdPrice(!showUsdPrice);
                  }}
                >
                  <Amount
                    showUsdPrice={showUsdPrice}
                    amount={Number(formatEther(amount))}
                    disableToggle
                    className="text-lg"
                  />
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};
