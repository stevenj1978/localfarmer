const express = require('express');
const { exec } = require('child_process');
const app = express();

app.use(express.json());

app.post('/webhook', (req, res) => {
    const payload = req.body;

    if (payload.ref === 'refs/heads/main') {
        console.log('Received push event. Pulling latest changes...');
        exec('git pull', (err, stdout, stderr) => {
            if (err) {
                console.error(`Pull error: ${stderr}`);
                return res.status(500).send('Pull failed');
            }
            console.log(`Pull result: ${stdout}`);
            res.status(200).send('Pull successful');
        });
    } else {
        res.status(200).send('Not a push to the main branch');
    }
});

app.listen(4000, () => {
    console.log('Listening for GitHub webhooks on port 4000');
});
