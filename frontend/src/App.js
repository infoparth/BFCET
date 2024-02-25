// App.js
import { Routes, Route } from "react-router-dom";
import React from "react";
import { BrowserRouter } from "react-router-dom";
import LandingPage from "./pages/users/landingpage.jsx";
import Dashboard from "./pages/users/dashboard";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
