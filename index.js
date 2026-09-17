const axios = require('axios');
const express = require('express');
const app = express()
const port =  process.env.PORT || 3000
const crypto = require('crypto')
require('dotenv').config()

let HOST_URL = process.env.URL 
const pendingAuth = new Map();
app.use(express.urlencoded({extended:false}))
app.get('/auth/callback',async (req, res) => {
    let code = req.query.code
    let state = req.query.state
    let ACCESS_TOKEN_RES = await axios.post('https://hackatime.hackclub.com/oauth/token',
        `client_id=Utwc3_2HeYUUZAYlRnaHQSqR7JhrHmygVjoumY_iqOY&code=${code}&grant_type=authorization_code&state${state}&redirect_uri=${HOST_URL}/auth/callback`,{
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  })
    let token = ACCESS_TOKEN_RES.data.access_token
    let qscode = crypto.randomBytes(32).toString('hex')
    pendingAuth.set(qscode, {
        token: token,
        expires: Date.now() + 60_000
    });
    res.redirect(`hackatime://auth/callback?code=${qscode}`)
})
app.post('/auth/exchange',async (req, res) => {
    let code = req.body.code
    const auth = pendingAuth.get(code);
    if (!auth || auth.expires < Date.now()) {
        return res.status(401).json({
            error: 'Invalid or expired code'
        });
    }
    pendingAuth.delete(code);
    res.json({
        access_token: auth.token
    });
})

app.listen(port, () => {
  console.log(`app listening on port ${port}`)
})