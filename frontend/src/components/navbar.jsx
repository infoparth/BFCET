import React, { useState } from "react";
import "./navbar.css";

const Navbar = () => {
  const [userWalletAddress, setUserWalletAddress] = useState("0x..."); // Replace with actual address or a placeholder
  return (
    <nav className="navbar">
      <div className="navbar-brand">Real-Chain</div>
      <ul className="navbar-links">
        <li>
          <a href="#">Home</a>
        </li>
        <li>
          <a href="#">About</a>
        </li>
        <li>
          <a href="#">Services</a>
        </li>
        <li>
          <a href="#">Contact</a>
        </li>
        <div className="wallet-address">Wallet: {userWalletAddress}</div>
      </ul>
    </nav>
  );
};

export default Navbar;
