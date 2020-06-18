'use strict';

const Mailgun = require('mailgun-js')

const axios = require('axios');
const reCapUrl = 'https://www.google.com/recaptcha/api/siteverify';

// eslint-disable-next-line no-unused-vars
module.exports.sendEmail = async (event, context, callback) => {
  console.log('Começando o request...');
  const bodyParams = JSON.parse(event.body);

  console.log(bodyParams.token)
  console.log(bodyParams.email)
  console.log(bodyParams.value)
  console.log(bodyParams.text)

  const params = {
    secret: process.env.RECAPTCHA_KEY,
    response: bodyParams.token
  };

  console.log(params)
  
  const verifyResult = await axios ({
    method: 'post',
    url: reCapUrl,
    params,
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Accept": "*/*"
    }
  });

  console.log('RESPOSTA DO GOOGLE[DATA] => ', verifyResult.data)
  console.log('RESPOSTA DO GOOGLE[BODY] => ', verifyResult.config)

  if (verifyResult.status === 200) {

    if (verifyResult.data['success'] === true) {
      console.log('RESPOSTA DO GOOGLE => ', verifyResult.data)
      let content = `${bodyParams.text} <br><br> <strong>Valor: R$${bodyParams.value}`
      try {
        const fetchGif = await axios.get(
          `${process.env.GIPHY_URL}/random`,
          {
            params: {
              api_key: process.env.GIPHY_API_KEY,
              tag: 'money',
              rating: 'g'
            }
          }
        );
  
        console.log(fetchGif.data)
  
        const imageTag = `
          <img
            src='${fetchGif.data.data.image_url}'
            width='${fetchGif.data.data.image_width}'
            height='${fetchGif.data.data.image_height}'
            alt='${fetchGif.data.data.title}'
            border='0'
          >
          </img>
        `
        content = `${bodyParams.text} <br><br> ${imageTag} <br> <strong>Valor: R$${bodyParams.value}`

      } catch (e) {
        console.log(e)
      }

      const mailgun = new Mailgun({apiKey: process.env.MAILGUN_API_KEY, domain: process.env.MAILGUN_DOMAIN});

      var data = {
        from: process.env.FROM_EMAIL,
        to: bodyParams.email,
        subject: 'Olá, Me pague o que dev.',
        html: content
      }

      console.log('Dados email => ', data)
      
      try {
        const mailgunRes = await mailgun.messages().send(data)
        console.log('Enviando email => ', mailgunRes)
        
        const response = {
          statusCode: 200,
          headers: {
            'Access-Control-Allow-Headers' : 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
          },
          body: JSON.stringify('Email enviado com sucesso, consagrado(a)!'),
        };
        return response;
      } catch (err) {
        const response = {
          statusCode: 403,
          headers: {
            'Access-Control-Allow-Headers' : 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
          },
          body: JSON.stringify(err),
        };
        return response;
      }
    }
  } else {
    const response = {
      statusCode: 401,
      headers: {
        'Access-Control-Allow-Headers' : 'Content-Type',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
      },
      body: JSON.stringify('verificação do recaptcha falhou. Isso ta com cheirin de SPAM.'),
    };
    console.log('verificação do recaptcha falhou. Isso ta com cheirin de SPAM.');
    return response;
  }
}
