package service

import (
	"context"
	"fmt"
	"mime/multipart"
	"os"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3Service struct {
	client *s3.Client
	bucket string
	region string
}

func NewS3Service() (*S3Service, error) {
	bucket := os.Getenv("AWS_S3_BUCKET")
	region := os.Getenv("AWS_REGION")
	accessKey := os.Getenv("AWS_ACCESS_KEY")
	secretKey := os.Getenv("AWS_SECRET_KEY")

	if bucket == "" || region == "" || accessKey == "" || secretKey == "" {
		return nil, fmt.Errorf("AWS credentials or configuration missing in environment")
	}

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")),
	)
	if err != nil {
		return nil, err
	}

	client := s3.NewFromConfig(cfg)

	return &S3Service{
		client: client,
		bucket: bucket,
		region: region,
	}, nil
}

func (s *S3Service) UploadFile(file *multipart.FileHeader, folder string, filename string) (string, error) {
	f, err := file.Open()
	if err != nil {
		return "", err
	}
	defer f.Close()

	key := fmt.Sprintf("%s/%s", folder, filename)

	_, err = s.client.PutObject(context.TODO(), &s3.PutObjectInput{
		Bucket: &s.bucket,
		Key:    &key,
		Body:   f,
		// ContentType: &file.Header.Get("Content-Type"), // Optional, let S3 detect or set it
	})
	if err != nil {
		return "", err
	}

	url := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucket, s.region, key)
	return url, nil
}
