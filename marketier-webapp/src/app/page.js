"use client"
import React, { useEffect } from 'react';
import Image from 'next/image'
import styles from './page.module.css'
import ResponsiveAppBar from './AppBar/page'
import Premiums from './Premiums/page'
import Homepage from './Homepage/page'
import { createTheme, ThemeProvider } from '@mui/material/styles';
import { Slide } from '@mui/material';
'use client'

import { createAppKit } from '@reown/appkit/react'
import { EthersAdapter } from '@reown/appkit-adapter-ethers'
import { mainnet, arbitrum } from '@reown/appkit/networks'

// 1. Get projectId at https://cloud.reown.com
const projectId = 'YOUR_PROJECT_ID'

// 2. Create a metadata object
const metadata = {
  name: 'My Website',
  description: 'My Website description',
  url: 'https://mywebsite.com', // origin must match your domain & subdomain
  icons: ['https://avatars.mywebsite.com/']
}

// 3. Create the AppKit instance
createAppKit({
  adapters: [new EthersAdapter()],
  metadata,
  networks: [mainnet, arbitrum],
  projectId,
  features: {
    analytics: true // Optional - defaults to your Cloud configuration
  }
})


const ethereumClient = new EthereumClient(wagmiConfig, chains)

const theme = createTheme({
  palette: {
    primary: {
      main: '#610080',  // Change this to the grey color you want
    },
  },
});

export default function Home() {
  
  let app;
  let analytics;

  const [appPage, setAppPage] = React.useState("home");

  const changeAppPage = (page) => {
    setAppPage(page)
  }

  return (
    <ThemeProvider theme={theme}>
    <main className={styles.main}>
    {/* <WagmiConfig config={wagmiConfig}> */}
      <ResponsiveAppBar changeAppPage={changeAppPage}/>
      <div className={styles.content}>
        {appPage === "home" && <Homepage changeAppPage={changeAppPage}/>}
      </div>
    {/* </WagmiConfig> */}
    {/* <Web3Modal projectId={projectId} ethereumClient={ethereumClient} /> */}
    </main>
    </ThemeProvider>
  )
}
